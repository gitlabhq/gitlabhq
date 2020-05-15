# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDefaultProjectDeletionProtectionToApplicationSettings < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/AddColumnWithDefault
    add_column_with_default :application_settings, :default_project_deletion_protection, :boolean, default: false, allow_null: false
    # rubocop:enable Migration/AddColumnWithDefault
  end

  def down
    remove_column :application_settings, :default_project_deletion_protection
  end
end
