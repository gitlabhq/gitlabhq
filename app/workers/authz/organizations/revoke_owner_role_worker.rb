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

        # Without an owner to act as, the user revokes their own role, which IAM's
        # self-delete rule always allows. Never another owner, since IAM would then
        # record an uninvolved person as having made this change.
        acting_owner = actor_id == user.id ? user : acting_owner_for(organization, actor_id)

        unless acting_owner
          log_self_revoke(organization, user, actor_id)
          acting_owner = user
        end

        iam_client.revoke_roles(
          [{ assignee_id: user.id, resource_id: organization.uuid }],
          organization_uuid: organization.uuid,
          token: token_for(organization, acting_owner)
        )
      rescue ::Authn::IamService::UpdateRelationshipsClient::RequestError => e
        handle_request_error(e, organization, user)
      end

      private

      # IAM records the user as making this change, so the log keeps who asked for it.
      def log_self_revoke(organization, user, actor_id)
        Gitlab::AppLogger.info(build_structured_payload_labkit(
          message: 'Organization admin role revoked as the user because no owner was available to act as',
          Labkit::Fields::GL_ORGANIZATION_ID => organization.id,
          Labkit::Fields::GL_USER_ID => user.id,
          requested_actor_id: actor_id
        ))
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
