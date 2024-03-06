# frozen_string_literal: true

module ProjectAccessTokens
  class RotateService < ::PersonalAccessTokens::RotateService
    extend ::Gitlab::Utils::Override

    alias_method :project, :resource

    override :valid_access_level?
    def valid_access_level?
      return true if current_user.can_admin_all_resources?
      return false unless current_user.can?(:manage_resource_access_tokens, project)

      token_access_level = project.team.max_member_access(token.user.id).to_i
      current_user_access_level = project.team.max_member_access(current_user.id).to_i

      token_access_level <= current_user_access_level
    end
  end
end
