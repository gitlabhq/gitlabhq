# frozen_string_literal: true

class AddActiveContextMigrations < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  FAILED_STATE_ENUM = 255
  INDEX_NAME = 'index_ai_active_context_migrations_on_connection_and_status'
  UNIQUE_INDEX_NAME = 'index_ai_active_context_migrations_on_connection_and_version'
  CONSTRAINT_NAME = 'c_ai_active_context_migrations_on_retries_left'
  VERSION_CONSTRAINT_NAME = 'c_ai_active_context_migrations_version_format'
  CONSTRAINT_QUERY = <<~SQL
    (retries_left > 0) OR (retries_left = 0 AND status = #{FAILED_STATE_ENUM})
  SQL

  def change
    create_table :ai_active_context_migrations do |t|
      # Fixed size columns (8 bytes)
      t.references :connection, index: false,
        foreign_key: { to_table: :ai_active_context_connections, on_delete: :cascade }, null: false
      t.datetime_with_timezone :started_at
      t.datetime_with_timezone :completed_at
      t.timestamps_with_timezone

      # Fixed size columns (4 bytes)
      t.integer :status, limit: 2, null: false, default: 0
      t.integer :retries_left, limit: 2, null: false

      # Variable size columns
      t.text :version, null: false, limit: 255
      t.jsonb :metadata, null: false, default: {}
      t.text :error_message, limit: 1024

      t.index [:connection_id, :status], name: INDEX_NAME
      t.index [:connection_id, :version], unique: true, name: UNIQUE_INDEX_NAME

      # Check constraint ensures retries_left is only non-zero for non-failed migrations
      t.check_constraint CONSTRAINT_QUERY, name: CONSTRAINT_NAME

      # Check constraint ensures version is a 14-digit timestamp format (YYYYMMDDHHMMSS)
      t.check_constraint "version ~ '^[0-9]{14}$'", name: VERSION_CONSTRAINT_NAME
    end
  end
end
