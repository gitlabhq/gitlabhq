# frozen_string_literal: true

class ChangeUserPreferenceOrganizationGroupsProjectsDisplayDefault < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def up
    change_column_default :user_preferences, :organization_groups_projects_display, from: 0, to: 1
  end

  def down
    change_column_default :user_preferences, :organization_groups_projects_display, from: 1, to: 0
  end
end
