# frozen_string_literal: true

class CreateUserAddOnAssignmentsHistory < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS user_add_on_assignments_history
      (
        assignment_id UInt64,
        namespace_path String DEFAULT '0/',
        user_id UInt64,
        purchase_id UInt64,
        add_on_name String,
        assigned_at DateTime64(6, 'UTC'),
        revoked_at Nullable(DateTime64(6, 'UTC'))
      )
      ENGINE = ReplacingMergeTree(assignment_id)
      PARTITION BY toYear(assigned_at)
      ORDER BY (namespace_path, assigned_at, user_id)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS user_add_on_assignments_history
    SQL
  end
end
