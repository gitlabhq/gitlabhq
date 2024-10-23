# frozen_string_literal: true

# This Service takes authentication tokens of multiple types, and will
# call a revocation for it if the token has access to the
# group or any of the group's descendants. If revocation is not
# possible, the token will be rotated or otherwise made unusable.
#
# If the token provided has access to the group and is revoked, it will
# be returned by the service with a :success status.
# If the token type is not supported, if the token doesn't have access
# to the group, or if any error occurs, a generic :failure status is
# returned.
#
# This Service does not create logs or Audit events. Those can be found
# at the API layer or in specific revocation services.
#
# This Service returns a ServiceResponse object.
module Groups # rubocop:disable Gitlab/BoundedContexts -- This service is strictly related to groups
  class AgnosticTokenRevocationService < Groups::BaseService
    AUDIT_SOURCE = :group_token_revocation_service

    def initialize(group, current_user, plaintext)
      @group = group
      @current_user = current_user
      @plaintext = plaintext.to_s
    end

    def execute
      return error("Feature not enabled") unless Feature.enabled?(:group_agnostic_token_revocation, group)
      return error("Group cannot be a subgroup") if group.subgroup?
      return error("Unauthorized") unless can?(current_user, :admin_group, group)

      @token = ::Authn::AgnosticTokenIdentifier.token_for(plaintext, AUDIT_SOURCE)
      @revocable = token.revocable unless token.blank?

      # Perform checks based on token type and group scope:
      case token
      when ::Authn::Tokens::PersonalAccessToken
        handle_personal_access_token
      when ::Authn::Tokens::DeployToken
        handle_deploy_token
      when ::Authn::Tokens::FeedToken
        handle_feed_token
      else
        error('Unsupported token type')
      end
    end

    private

    attr_reader :plaintext, :group, :current_user, :token, :revocable

    def success(revocable, type, api_entity: nil)
      api_entity ||= type
      ServiceResponse.success(
        message: "#{type} is revoked",
        payload: {
          revocable: revocable,
          type: type,
          api_entity: api_entity
        }
      )
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def handle_personal_access_token
      return error('PAT not found') unless revocable

      if user_has_group_membership?(revocable.user)
        # Only revoke active tokens. (Ignore expired tokens)
        token.revoke!(current_user) if revocable.active?

        # Always validate that, if we're returning token info, it
        # has been successfully revoked
        return success(revocable, 'PersonalAccessToken') if revocable.reset.revoked?
      end

      # If we get here the token exists but either:
      #  - didn't belong to the group or descendants
      #  - did, but was already expired
      #  - does and is active, but revocation failed for some reason
      error('PAT revocation failed')
    end

    # Validate whether the user has access to a group or any of its
    # descendants. Includes membership that might not be active, but
    # could be later, e.g. bans. Includes membership of non-human
    # users.
    def user_has_group_membership?(user)
      ::GroupMember
        .with_user(user)
        .with_source_id(group.self_and_descendants)
        .any? ||
        ::ProjectMember
        .with_user(user)
        .in_namespaces(group.self_and_descendants)
        .any?
    end

    def handle_deploy_token
      return error('DeployToken not found') unless revocable && revocable.group_type?

      if group.self_and_descendants.include?(revocable.group)
        token.revoke!(current_user) if revocable.active?

        return success(revocable, 'DeployToken') if revocable.reset.revoked?
      end

      error('DeployToken revocation failed')
    end

    def handle_feed_token
      return error('Feed Token not found') unless revocable

      if user_has_group_membership?(revocable)
        current_token = revocable.feed_token

        response = token.revoke!(current_user)

        # Always validate that, if we're returning token info, it
        # has been successfully revoked. Feed tokens can only be rotated
        # so we also check that the old and new value are different.
        if response.success? && !ActiveSupport::SecurityUtils.secure_compare(current_token, revocable.reset.feed_token)
          return success(revocable, 'FeedToken', api_entity: 'UserSafe')
        end
      end

      # If we get here the feed token exists but either:
      #  - the user didn't belong to the group or descendants
      #  - rotation failed for some reason
      error('Feed token revocation failed')
    end
  end
end
