# frozen_string_literal: true

module Authz
  module Organizations
    # Revokes the org owner's Organization Administrator role assignment
    # when a member stops being an owner.
    class RevokeOwnerRoleWorker
      include Authz::Organizations::OwnerRoleSync

      idempotent!
      sidekiq_options retry: 5

      def perform(organization_id, user_id, actor_id = nil)
        organization, user = organization_and_user(organization_id, user_id)
        return unless organization

        if currently_owner?(organization, user)
          return log_skip(reason: 'user is an owner of this organization again', organization_id: organization.id,
            user_id: user.id)
        end

        # A self-revoke authorizes as themselves via IAM's self-delete rule,
        # since deleting your own grant can only reduce access. Otherwise, no
        # fallback to another owner: borrowing their identity would make
        # IAM's record of who performed this write false.
        acting_owner = actor_id == user.id ? user : acting_owner_for(organization, actor_id)

        return unauthorized_revoke(organization, user) unless acting_owner

        iam_client.revoke_roles(
          [{ assignee_id: user.id, resource_id: organization.uuid }],
          organization_uuid: organization.uuid,
          token: token_for(organization, acting_owner)
        )
      rescue ::Authn::IamService::UpdateRelationshipsClient::RequestError => e
        handle_request_error(e, organization, user)
      end

      private

      # Distinct from log_skip: retained access nobody is aware of is a
      # different class of event than a missing record, and this never
      # reaches IAM, so DataAccessClient's own reporting never fires for it.
      def unauthorized_revoke(organization, user)
        error = UnauthorizedRevokeError.new(
          "no acting owner available to authorize revoking organization_admin from user #{user.id} " \
            "in organization #{organization.id}"
        )
        Gitlab::ErrorTracking.track_exception(error, organization_id: organization.id, user_id: user.id)
        log_error(error.message, organization_id: organization.id, user_id: user.id)
      end

      # :not_found means the subject was never granted anything at all - a
      # legitimate outcome for a revoke (nothing to remove), not a failure.
      def handle_request_error(error, organization, user)
        return if error.reason == :not_found
        raise RequestError, error.message if retryable_reason?(error.reason)

        log_error(error.message, organization_id: organization.id, user_id: user.id)
      end
    end
  end
end
