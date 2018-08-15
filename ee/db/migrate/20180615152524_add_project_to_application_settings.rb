# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddProjectToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :application_settings, :file_template_project_id, :integer
    add_concurrent_foreign_key :application_settings, :projects, column: :file_template_project_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :application_settings, column: :file_template_project_id
    remove_column :application_settings, :file_template_project_id, :integer
  end
end
