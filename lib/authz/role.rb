# frozen_string_literal: true

module Authz
  class Role
    def self.roles_user_can_assign(current_access_level, roles = nil)
      available_roles = roles || Gitlab::Access.options_with_owner

      available_roles.select do |_role_name, access_level|
        Gitlab::Access.level_encompasses?(current_access_level: current_access_level, level_to_assign: access_level)
      end
    end
  end
end
