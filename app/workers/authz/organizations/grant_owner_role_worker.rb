# frozen_string_literal: true

module Authz
  module Organizations
    # Grants the org owner's Organization Administrator role (ADR-021),
    # scoped to the organization itself. actor_id is the owner whose token
    # authorizes the write, falling back to the grantee.
    class GrantOwnerRoleWorker
      include Authz::Organizations::OwnerRoleSync

      idempotent!
      sidekiq_options retry: 5

      def perform(organization_id, user_id, actor_id = nil)
        organization, user = organization_and_user(organization_id, user_id)
        return unless organization

        unless currently_owner?(organization, user)
          return log_skip(reason: 'user is no longer an owner of this organization', organization_id: organization.id,
            user_id: user.id)
        end

        # Prefers the acting owner, falling back to the newly-promoted
        # owner themselves.
        acting_owner = acting_owner_for(organization, actor_id) || user

        iam_client.grant_roles(
          [{ assignee_id: user.id, resource_id: organization.uuid, role_id: organization_admin_role_id }],
          organization_uuid: organization.uuid,
          token: token_for(organization, acting_owner)
        )
      rescue ::Authn::IamService::UpdateRelationshipsClient::RequestError => e
        handle_request_error(e, organization, user)
      end

      private

      def handle_request_error(error, organization, user)
        raise RequestError, error.message if retryable_reason?(error.reason)

        log_error(error.message, organization_id: organization.id, user_id: user.id)
      end
    end
  end
end
