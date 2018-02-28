# rubocop:disable Migration/RemoveColumn
class MigrateProjectStatistics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Removes two columns from the projects table'

  def up
    # convert repository_size in float (megabytes) to integer (bytes),
    # initialize total storage_size with repository_size
    execute <<-EOF
      INSERT INTO project_statistics (project_id, namespace_id, commit_count, storage_size, repository_size)
        SELECT id, namespace_id, commit_count, (repository_size * 1024 * 1024), (repository_size * 1024 * 1024) FROM projects
    EOF

    remove_column :projects, :repository_size
    remove_column :projects, :commit_count
  end

  # rubocop: disable Migration/AddColumn
  def down
    add_column :projects, :repository_size, :float, default: 0.0
    add_column :projects, :commit_count, :integer, default: 0
  end
end
