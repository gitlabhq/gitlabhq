# frozen_string_literal: true

class AddOrganizationGroupsProjectsDisplay < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :user_preferences, :organization_groups_projects_display, :smallint, default: 0, null: false
  end
end
