# frozen_string_literal: true

module Organizations
  class ActivateService
    include Gitlab::InternalEventsTracking

    attr_reader :current_user, :params, :organization

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
      @organization = Organizations::Organization.find_by_id(@params[:organization_id])
    end

    def execute
      return error(_('Organization not found')) unless organization
      return error(_('Insufficient permissions')) unless allowed?
      return error(_('Organization must be confirmed')) unless organization.state == 'confirmed'

      track_transfer_started

      response = nil

      ApplicationRecord.transaction do
        transfer_result = transfer_top_level_groups

        if transfer_result.error?
          response = transfer_result
          raise ActiveRecord::Rollback
        end

        create_organization_users

        organization.activate

        if organization.active?
          response = ServiceResponse.success(payload: { organization: organization })
        else
          response = error(
            organization.errors.full_messages.to_sentence.presence || _('Organization could not be activated'),
            reason: :activation
          )
          raise ActiveRecord::Rollback
        end
      end

      publish_activated_event if response&.success?

      track_transfer_finished(response)

      response
    end

    private

    # Tracked inline rather than through Gitlab::InternalEvents::ServiceTracking
    # because that concern only fires after `execute` returns, which cannot
    # express a start event or skip the early-return guards above.
    def track_transfer_started
      track_transfer_event('transfer_tlg_resources_into_an_organization_started')
    end

    def track_transfer_finished(response)
      if response&.success?
        track_transfer_event('transfer_tlg_resources_into_an_organization_succeeded', **transferred_counts)
      else
        track_transfer_event('transfer_tlg_resources_into_an_organization_failed', label: failure_reason(response))
      end
    end

    # Counted after the transfer, not on the start event: ConfirmService moves only
    # the top-level groups, so descendants and projects still carry the old
    # organization_id until `transfer_top_level_groups` runs.
    def transferred_counts
      {
        value: Group.in_organization(organization).count,
        projects_count: Project.in_organization(organization).count,
        users_count: organization.organization_users.count
      }
    end

    def track_transfer_event(event_name, **additional_properties)
      track_internal_event(
        event_name,
        user: current_user,
        additional_properties: { target_organization_id: organization.id, **additional_properties }
      )
    end

    def failure_reason(response)
      response&.reason&.to_s
    end

    def publish_activated_event
      Gitlab::EventStore.publish(
        Organizations::ActivatedEvent.build(organization: organization)
      )
    end

    def transfer_top_level_groups
      aggregated_errors = []

      organization.groups.top_level.find_each do |group|
        result = Organizations::Transfer::GroupsService.new(
          group: group,
          new_organization: organization,
          current_user: current_user
        ).execute

        next if result.success?
        # The group and all of its descendants are already in the target
        # organization, so there is nothing to do for this group.
        next if already_transferred_error?(result)

        aggregated_errors << result
      end

      return ServiceResponse.success if aggregated_errors.empty?

      ServiceResponse.error(
        message: aggregated_errors.map(&:message).join('; '),
        reason: :group_transfer,
        payload: { organization: organization, failed_transfers: aggregated_errors }
      )
    end

    def create_organization_users
      Organizations::Transfer::OrganizationUsersService.new(organization: organization).execute
    end

    def already_transferred_error?(result)
      result.reason == :already_transferred
    end

    def allowed?
      current_user&.can?(:update_organization, organization)
    end

    def error(message, reason: nil)
      ServiceResponse.error(message: message, reason: reason, payload: { organization: organization })
    end
  end
end
