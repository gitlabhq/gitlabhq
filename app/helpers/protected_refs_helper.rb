# frozen_string_literal: true

module ProtectedRefsHelper
  include Gitlab::Utils::StrongMemoize

  def protected_access_levels_for_dropdowns
    {
      create_access_levels: protected_access_level_dropdown_roles,
      push_access_levels: protected_access_level_dropdown_roles,
      merge_access_levels: protected_access_level_dropdown_roles
    }
  end

  def protected_access_level_dropdown_roles
    roles = ProtectedRef::AccessLevel.human_access_levels.map do |id, text|
      { id: id, text: text, before_divider: true }
    end

    { roles: roles }
  end
  strong_memoize_attr(:protected_access_level_dropdown_roles)
end
