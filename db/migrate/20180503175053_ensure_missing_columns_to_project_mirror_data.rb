class EnsureMissingColumnsToProjectMirrorData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :project_mirror_data, :status, :string unless column_exists?(:project_mirror_data, :status)
    add_column :project_mirror_data, :jid, :string unless column_exists?(:project_mirror_data, :jid)
    add_column :project_mirror_data, :last_error, :text unless column_exists?(:project_mirror_data, :last_error)
  end

  def down
    # db/migrate/20180502122856_create_project_mirror_data.rb will remove the table
  end
end
