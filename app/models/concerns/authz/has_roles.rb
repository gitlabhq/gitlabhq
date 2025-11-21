# frozen_string_literal: true

module Authz
  module HasRoles
    extend ActiveSupport::Concern

    def can_assign_role?(current_user, access_level)
      return true unless access_level

      max_access_level = max_member_access_for_user(current_user)

      Gitlab::Access.level_encompasses?(current_access_level: max_access_level, level_to_assign: access_level)
    end
  end
end

Authz::HasRoles.prepend_mod
