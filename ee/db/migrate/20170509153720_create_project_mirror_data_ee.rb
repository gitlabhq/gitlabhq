class CreateProjectMirrorDataEE < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # When moving from CE to EE, project_mirror_data may already exist, but will
    # not have all the required columns.
    if table_exists?(:project_mirror_data)
      add_column_with_default :project_mirror_data, :retry_count, :integer, default: 0, allow_null: false unless column_exists?(:project_mirror_data, :retry_count)
      add_column :project_mirror_data, :last_update_started_at, :datetime_with_timezone unless column_exists?(:project_mirror_data, :last_update_started_at)
      add_column :project_mirror_data, :last_update_scheduled_at, :datetime_with_timezone unless column_exists?(:project_mirror_data, :last_update_scheduled_at)
      add_column :project_mirror_data, :next_execution_timestamp, :datetime_with_timezone unless column_exists?(:project_mirror_data, :next_execution_timestamp)
    else
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
  end

  def down
    drop_table :project_mirror_data if table_exists?(:project_mirror_data)
  end

  def timestamp
    return 'TIMESTAMP' if Gitlab::Database.postgresql?

    'DATETIME'
  end
end
