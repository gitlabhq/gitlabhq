# frozen_string_literal: true

module ResourceAccessTokens
  class RotateService < ::PersonalAccessTokens::RotateService
    extend ::Gitlab::Utils::Override

    def initialize(current_user, token, resource = nil)
      @current_user = current_user
      @token = token
      @resource = resource
    end

    def execute(params = {})
      super
    end

    attr_reader :resource

    private

    override :create_access_token
    def create_access_token(params)
      target_user = token.user

      unless valid_access_level?
        return error_response(
          _("Not eligible to rotate token with access level higher than the user")
        )
      end

      new_token = target_user.personal_access_tokens.create(create_token_params(token, params))

      if new_token.persisted?
        update_bot_membership(target_user, new_token.expires_at)

        return success_response(new_token)
      end

      error_response(new_token.errors.full_messages.to_sentence)
    end

    def update_bot_membership(target_user, expires_at)
      target_user.members.update(expires_at: expires_at)
    end

    def valid_access_level?
      return true if admin_all_resources?
      return false unless can_manage_tokens?

      token_access_level <= current_user_access_level
    end

    def admin_all_resources?
      current_user.can_admin_all_resources?
    end

    def can_manage_tokens?
      current_user.can?(:manage_resource_access_tokens, resource)
    end

    def token_access_level
      if resource.is_a? Project
        resource.team.max_member_access(token.user.id).to_i
      else
        resource.max_member_access_for_user(token.user).to_i
      end
    end

    def current_user_access_level
      if resource.is_a? Project
        resource.team.max_member_access(current_user.id).to_i
      else
        resource.max_member_access_for_user(current_user).to_i
      end
    end
  end
end
