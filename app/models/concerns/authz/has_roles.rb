# frozen_string_literal: true

module Authz
  module HasRoles
    extend ActiveSupport::Concern

    def roles_user_can_assign(current_user, roles = nil)
      available_roles = roles || Gitlab::Access.options_with_owner
      max_access_level = max_member_access_for_user(current_user)

      available_roles.select do |_role_name, access_level|
        Gitlab::Access.level_encompasses?(current_access_level: max_access_level, level_to_assign: access_level)
      end
    end

    def can_assign_role?(current_user, access_level)
      return true unless access_level

      max_access_level = max_member_access_for_user(current_user)

      Gitlab::Access.level_encompasses?(current_access_level: max_access_level, level_to_assign: access_level)
    end
  end
end

Authz::HasRoles.prepend_mod
