# frozen_string_literal: true

module Authz
  module Organizations
    # Grants the org owner's Organization Administrator role (ADR-021),
    # scoped to the organization itself. actor_id is the owner whose token
    # authorizes the write, falling back to an owner from the batch itself.
    class GrantOwnerRoleWorker
      include Authz::Organizations::OwnerRoleSync

      idempotent!
      sidekiq_options retry: 5

      BATCH_SIZE = 100

      # A nil user_id syncs every current owner, so callers that just wrote a
      # whole owner set enqueue one job instead of looping themselves.
      def perform(organization_id, user_id = nil, actor_id = nil)
        organization = organization_from(organization_id)
        unless organization
          return log_skip(reason: 'organization not found', organization_id: organization_id, user_id: user_id)
        end

        owner_rows = organization.organization_users.owners
        owner_rows = owner_rows.by_user(user_id) if user_id
        acting_owner = acting_owner_for(organization, actor_id)
        counts = { granted: 0, skipped_instance_admins: 0, failed: 0 }

        owner_rows.each_batch(of: BATCH_SIZE) do |batch|
          users = ::User.id_in(batch.map(&:user_id))
          admins, owners = users.partition { |user| admin_flag_owner_row?(organization, user) }
          counts[:skipped_instance_admins] += admins.size
          next if owners.empty?

          granted = grant_batch(organization, owners.map(&:id), acting_owner || owners.first)
          counts[:granted] += granted
          counts[:failed] += owners.size - granted
        end

        log_run(organization, user_id, counts)
      end

      private

      # An instance admin's owner row on their home organization is written by
      # the admin flag, not by anyone choosing them as owner, so it must not
      # become an organization_admin tuple. Owner rows elsewhere are deliberate.
      def admin_flag_owner_row?(organization, user)
        # rubocop:disable Cop/UserAdmin -- data check on the flag itself, not an authorization decision
        user.admin? && organization.id == user.organization_id
        # rubocop:enable Cop/UserAdmin
      end

      # Returns how many owners were granted. A non-retryable failure is logged
      # against each owner in the batch and the remaining batches still run;
      # retryable ones raise so the whole job retries.
      def grant_batch(organization, user_ids, acting_owner)
        role_id = organization_admin_role_id
        assignments = user_ids.map do |user_id|
          { assignee_id: user_id, resource_id: organization.uuid, role_id: role_id }
        end

        iam_client.grant_roles(
          assignments,
          organization_uuid: organization.uuid,
          token: token_for(organization, acting_owner)
        )

        user_ids.size
      rescue ::Authn::IamService::UpdateRelationshipsClient::RequestError => e
        raise RequestError, e.message if retryable_reason?(e.reason)

        user_ids.each { |user_id| log_error(e.message, organization_id: organization.id, user_id: user_id) }
        0
      end

      # One line per run, so a missing tuple can be traced to whether the sync
      # ran for that owner and what it decided. All zeros for a given user_id
      # means that user holds no owner row here.
      def log_run(organization, user_id, counts)
        payload = {
          message: 'Organization admin role sync finished',
          Labkit::Fields::GL_ORGANIZATION_ID => organization.id,
          Labkit::Fields::GL_USER_ID => user_id,
          granted_count: counts[:granted],
          skipped_instance_admin_count: counts[:skipped_instance_admins],
          failed_count: counts[:failed]
        }.compact

        Gitlab::AppLogger.info(build_structured_payload_labkit(**payload))
      end
    end
  end
end
