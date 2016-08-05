# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddCiConfigFileToProject < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_column :projects, :ci_config_file, :string
  end

  def down
    remove_column :projects, :ci_config_file
  end
end
