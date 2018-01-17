class CreateProjectMirrorData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    execute <<-SQL
      CREATE TABLE project_mirror_data
      AS (
        SELECT id AS project_id,
          0 AS retry_count,
          CAST(NULL AS #{timestamp}) AS last_update_started_at,
          CAST(NULL AS #{timestamp}) AS last_update_scheduled_at,
          NOW() AS next_execution_timestamp,
          NOW() AS created_at,
          NOW() AS updated_at
        FROM projects
        WHERE mirror IS TRUE
      );
    SQL

    add_column :project_mirror_data, :id, :primary_key
    change_column_default :project_mirror_data, :retry_count, 0
    change_column_null :project_mirror_data, :retry_count, false
    add_concurrent_foreign_key :project_mirror_data, :projects, column: :project_id
    add_concurrent_index :project_mirror_data, [:project_id], unique: true
  end

  def down
    drop_table :project_mirror_data if table_exists?(:project_mirror_data)
  end

  def timestamp
    return 'TIMESTAMP' if Gitlab::Database.postgresql?

    'DATETIME'
  end
end
