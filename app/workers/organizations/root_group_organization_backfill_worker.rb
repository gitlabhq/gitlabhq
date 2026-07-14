# frozen_string_literal: true

module Organizations
  # Worker that subscribes to feature flag events for `root_group_organization_backfill`
  # and handles automatic organization creation and group transfers for specific actors.
  #
  # On enable (actor):
  # - Creates a new organization matching the root group's name/path
  # - Transfers the root group from default organization to the new organization
  #
  # On disable (actor):
  # - Transfers the root group back to the default organization (if in unconfirmed org)
  # - Deletes the unconfirmed organization if it has no remaining root groups
  #
  # Note: Global enable/disable operations are not currently supported as they
  # require batching for safe rollout at scale.
  class RootGroupOrganizationBackfillWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :sticky
    idempotent!

    feature_category :organization
    urgency :low

    defer_on_database_health_signal :gitlab_main, [:namespaces, :organizations_organization], 1.minute

    def handle_event(event)
      operation = event.data[:operation]
      actor = event.data[:actor]

      group = find_root_group_from_actor(actor)
      return unless group

      case operation
      when Feature::OPERATION_ENABLED_ACTOR
        backfill_group(group) if Feature.enabled?(:root_group_organization_backfill, group)
      when Feature::OPERATION_DISABLED_ACTOR
        revert_group(group) if Feature.disabled?(:root_group_organization_backfill, group)
      end
    end

    private

    def find_root_group_from_actor(actor)
      return unless actor

      parts = actor.split(':')
      return unless parts.length == 2 && parts[0] == 'Group'

      group = Group.find_by_id(parts[1].to_i)
      group if group&.root?
    end

    # rubocop:disable Gitlab/AvoidDefaultOrganization -- Required for backfill operations
    def default_organization
      Organization.default_organization
    end
    # rubocop:enable Gitlab/AvoidDefaultOrganization

    def backfill_group(group)
      unless group.organization_id == default_organization&.id
        return log_info('Group not in default organization, skipping backfill', group_id: group.id)
      end

      new_org = create_organization_for_group(group)
      transfer_group_to_organization(group, new_org)
    end

    def revert_group(group)
      if group.organization_id == default_organization&.id
        return log_info('Group already in default organization, skipping revert', group_id: group.id)
      end

      current_org = group.organization
      transfer_group_to_organization(group, default_organization)

      organization_deleted = current_org.groups.top_level.none?
      current_org.destroy if organization_deleted
    end

    def create_organization_for_group(group)
      result = try_create_organization(group, group.path)

      if result.error? && path_validation_error?(result)
        fallback_path = "organization-#{group.id}"
        result = try_create_organization(group, fallback_path)
      end

      unless result.success?
        log_error('Failed to create organization', group_id: group.id, error_message: result.message)
        raise "Failed to create organization for group #{group.id}: #{result.message}"
      end

      result.payload[:organization]
    end

    def try_create_organization(group, path)
      Organizations::CreateService.new(
        current_user: nil,
        params: {
          name: group.name,
          path: path,
          state: :unconfirmed,
          visibility_level: group.visibility_level
        }
      ).execute(skip_authorization: true)
    end

    def path_validation_error?(result)
      result.message.to_s.include?('Path')
    end

    def transfer_group_to_organization(group, organization)
      result = Organizations::Transfer::TopLevelGroupService.new(
        groups: group,
        new_organization: organization,
        current_user: nil,
        skip_authorization: true
      ).execute

      return if result.success?

      log_error('Failed to transfer group',
        group_id: group.id,
        Labkit::Fields::GL_ORGANIZATION_ID => organization.id,
        error_message: result.message)
      raise "Failed to transfer group #{group.id} to organization #{organization.id}: #{result.message}"
    end

    def log_info(message, **extra)
      logger.info(structured_payload(message: message, **extra))
    end

    def log_error(message, **extra)
      logger.error(structured_payload(message: message, **extra))
    end
  end
end
