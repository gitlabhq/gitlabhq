# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDefaultProjectCreationApplicationSetting < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    unless column_exists?(:application_settings, :default_project_creation)
      add_column(:application_settings, :default_project_creation, :integer, default: 2, null: false)
    end
  end

  def down
    if column_exists?(:application_settings, :default_project_creation)
      remove_column(:application_settings, :default_project_creation)
    end
  end
end
