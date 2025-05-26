# frozen_string_literal: true

class CreateUserAddOnAssignmentsHistoryWithMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS user_addon_assignments_history
      (
        assignment_id UInt64,
        namespace_path String DEFAULT '0/',
        user_id UInt64,
        purchase_id UInt64,
        add_on_name String,
        assigned_at AggregateFunction(min, Nullable(DateTime64(6, 'UTC'))),
        revoked_at AggregateFunction(max, Nullable(DateTime64(6, 'UTC')))
      )
      ENGINE = AggregatingMergeTree()
      ORDER BY (namespace_path, user_id, assignment_id)
    SQL

    execute <<~SQL
      CREATE TABLE IF NOT EXISTS subscription_user_add_on_assignment_versions
      (
        id UInt64,
        organization_id UInt64,
        item_id UInt64,
        user_id UInt64,
        purchase_id UInt64,
        namespace_path String,
        add_on_name String,
        event String,
        created_at DateTime64(6, 'UTC'),
        version DateTime64(6, 'UTC') DEFAULT NOW(),
        deleted Boolean DEFAULT false
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      ORDER BY (namespace_path, user_id, item_id, event, id)
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW user_addon_assignments_history_mv TO user_addon_assignments_history AS
          SELECT
          item_id as assignment_id,
          namespace_path,
          purchase_id,
          add_on_name,
          user_id,
          minState(CASE WHEN event = 'create' THEN created_at ELSE NULL END) as assigned_at,
          maxState(CASE WHEN event = 'destroy' THEN created_at ELSE NULL END) as revoked_at
          FROM subscription_user_add_on_assignment_versions
          GROUP BY item_id, namespace_path, user_id, purchase_id, add_on_name
    SQL
  end

  def down
    execute "DROP VIEW IF EXISTS user_addon_assignments_history_mv"

    execute "DROP TABLE IF EXISTS user_addon_assignments_history"

    execute "DROP TABLE IF EXISTS subscription_user_add_on_assignment_versions"
  end
end
