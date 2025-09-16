# frozen_string_literal: true

module GroupAccessTokens
  class RotateService < ::PersonalAccessTokens::RotateService
    extend ::Gitlab::Utils::Override

    alias_method :group, :resource

    override :valid_access_level?
    def valid_access_level?
      return true if current_user.can_admin_all_resources?
      return false unless current_user.can?(:manage_resource_access_tokens, group)

      token_access_level = group.max_member_access_for_user(token.user).to_i
      current_user_access_level = group.max_member_access_for_user(current_user).to_i

      Authz::Role.access_level_encompasses?(
        current_access_level: current_user_access_level,
        level_to_assign: token_access_level
      )
    end

    private

    override :track_rotation_event
    def track_rotation_event
      track_internal_event(
        'rotate_grat',
        user: target_user,
        namespace: group,
        project: nil
      )
    end
  end
end
