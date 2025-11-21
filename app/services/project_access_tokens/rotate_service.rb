# frozen_string_literal: true

module ProjectAccessTokens
  class RotateService < ::PersonalAccessTokens::RotateService
    extend ::Gitlab::Utils::Override

    alias_method :project, :resource

    override :valid_access_level?
    def valid_access_level?
      return false unless current_user.can?(:manage_resource_access_tokens, project)

      token_access_level = project.max_member_access_for_user(token.user).to_i
      project.can_assign_role?(current_user, token_access_level)
    end

    private

    override :track_rotation_event
    def track_rotation_event
      track_internal_event(
        'rotate_prat',
        user: target_user,
        namespace: project.namespace,
        project: project
      )
    end
  end
end
