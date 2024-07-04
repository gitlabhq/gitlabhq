# frozen_string_literal: true

# This Service takes an authentication token of multiple types, and will
# call a RevokeService for it if the token has access to the group or
# any of the group's descendants.
#
# If the token provided has access to the group and is revoked, it will
# be returned by the service with a :success status.
# If the token type is not supported, if the token doesn't have access
# to the group, or if any error occurs, a generic :failure status is
# returned.
#
# This Service does not create logs or Audit events. Those can be found
# at the API layer or in specific RevokeServices.
#
# This Service returns a ServiceResponse and will:
#   - include the token object at payload[:token]
#   - the token's class at payload[:type]
module Groups # rubocop:disable Gitlab/BoundedContexts -- This service is strictly related to groups
  class AgnosticTokenRevocationService < Groups::BaseService
    AUDIT_SOURCE = :group_token_revocation_service

    attr_reader :token

    def initialize(group, current_user, plaintext)
      @group = group
      @current_user = current_user
      @plaintext = plaintext.to_s
    end

    def execute
      return error("Feature not enabled") unless Feature.enabled?(:group_agnostic_token_revocation, group)
      return error("Group cannot be a subgroup") if group.subgroup?
      return error("Unauthorized") unless can?(current_user, :admin_group, group)

      # Determine the type of token
      if plaintext.start_with?(Gitlab::CurrentSettings.current_application_settings.personal_access_token_prefix,
        'glpat-')
        @token = PersonalAccessToken.find_by_token(plaintext)
        return error('PAT not found') unless token

        handle_personal_access_token
      elsif plaintext.start_with?(DeployToken::DEPLOY_TOKEN_PREFIX)
        @token = DeployToken.find_by_token(plaintext)
        return error('DeployToken not found') unless token && token.group_type?

        handle_deploy_token
      else
        error('Unsupported token type')
      end
    end

    private

    attr_reader :plaintext, :group, :current_user

    def success(token, type)
      ServiceResponse.success(
        message: "#{type} is revoked",
        payload: {
          token: token,
          type: type
        }
      )
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def handle_personal_access_token
      if user_has_group_membership?
        # Only revoke active tokens. (Ignore expired tokens)
        if token.active?
          ::PersonalAccessTokens::RevokeService.new(
            current_user,
            token: token,
            source: AUDIT_SOURCE
          ).execute
        end

        # Always validate that, if we're returning token info, it
        # has been successfully revoked
        return success(token, 'PersonalAccessToken') if token.reset.revoked?
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
    def user_has_group_membership?
      ::GroupMember
        .with_user(token.user)
        .with_source_id(group.self_and_descendants)
        .any? ||
        ::ProjectMember
        .with_user(token.user)
        .in_namespaces(group.self_and_descendants)
        .any?
    end

    def handle_deploy_token
      if group.self_and_descendants.include?(token.group)
        if token.active?
          service = ::Groups::DeployTokens::RevokeService.new(
            token.group,
            current_user,
            { id: token.id }
          )

          service.source = AUDIT_SOURCE
          service.execute
        end

        return success(token, 'DeployToken') if token.reset.revoked?
      end

      error('DeployToken revocation failed')
    end
  end
end
