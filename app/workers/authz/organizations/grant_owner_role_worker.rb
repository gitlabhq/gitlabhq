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
        granted = false

        owner_rows.each_batch(of: BATCH_SIZE) do |batch|
          owners = grantable_owners(organization, batch)
          next if owners.empty?

          granted = true
          grant_batch(organization, owners.map(&:id), acting_owner || owners.first)
        end

        return if granted || user_id.nil?

        log_skip(reason: 'user is not a grantable owner of this organization', organization_id: organization.id,
          user_id: user_id)
      end

      private

      def grantable_owners(organization, batch)
        ::User.id_in(batch.map(&:user_id)).reject { |owner| admin_flag_owner_row?(organization, owner) }
      end

      # An instance admin's owner row on their home organization is written by
      # the admin flag, not by anyone choosing them as owner, so it must not
      # become an organization_admin tuple. Owner rows elsewhere are deliberate.
      def admin_flag_owner_row?(organization, user)
        # rubocop:disable Cop/UserAdmin -- data check on the flag itself, not an authorization decision
        user.admin? && organization.id == user.organization_id
        # rubocop:enable Cop/UserAdmin
      end

      # A non-retryable failure is logged against the owners in that batch
      # and the remaining batches still run; retryable ones raise so the whole
      # job retries.
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
      rescue ::Authn::IamService::UpdateRelationshipsClient::RequestError => e
        raise RequestError, e.message if retryable_reason?(e.reason)

        user_ids.each { |user_id| log_error(e.message, organization_id: organization.id, user_id: user_id) }
      end
    end
  end
end
