# frozen_string_literal: true

module Authz
  class Role
    def self.access_level_encompasses?(current_access_level:, level_to_assign:)
      # Roles that don't follow the inherited hierarchy can only be assigned by owners
      # or by users with the same role
      non_hierarchy_roles = [Gitlab::Access::PLANNER]

      if non_hierarchy_roles.include?(level_to_assign)
        return current_access_level.in?([Gitlab::Access::OWNER, level_to_assign])
      end

      level_to_assign.to_i <= current_access_level.to_i
    end

    def self.roles_user_can_assign(current_access_level, roles = nil)
      available_roles = roles || Gitlab::Access.options_with_owner

      available_roles.select do |_role_name, access_level|
        access_level_encompasses?(current_access_level: current_access_level, level_to_assign: access_level)
      end
    end
  end
end
