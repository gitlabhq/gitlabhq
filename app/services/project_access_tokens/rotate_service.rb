# frozen_string_literal: true

module ProjectAccessTokens
  class RotateService < ::PersonalAccessTokens::RotateService
    extend ::Gitlab::Utils::Override

    def initialize(current_user, token, resource = nil)
      @current_user = current_user
      @token = token
      @project = resource
    end

    def execute(params = {})
      super
    end

    attr_reader :project

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
      return true if current_user.can_admin_all_resources?
      return false unless current_user.can?(:manage_resource_access_tokens, project)

      token_access_level = project.team.max_member_access(token.user.id).to_i
      current_user_access_level = project.team.max_member_access(current_user.id).to_i

      return true if token_access_level.to_i <= current_user_access_level

      false
    end
  end
end
