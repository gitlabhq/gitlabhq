# frozen_string_literal: true

class MigrateAiDuoChatEventsToAiUsageEvents < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  BATCH_SIZE = 1000
  NEW_EVENT_TYPE = 6

  def up
    table = Gitlab::Database::PostgresPartitionedTable.find_by_name_in_current_schema("ai_usage_events")
    return if table.postgres_partitions.empty?

    model = define_batchable_model(:ai_duo_chat_events, connection: connection)

    model.each_batch(column: :id, of: BATCH_SIZE) do |relation|
      execute <<~SQL
      INSERT INTO ai_usage_events
      (
        timestamp,
        user_id,
        organization_id,
        created_at,
        event,
        extras,
        namespace_id
      )
      SELECT
        timestamp,
        user_id,
        organization_id,
        created_at,
        #{NEW_EVENT_TYPE} AS event,
        payload AS extras,
        CASE
          WHEN namespace_path IS NULL THEN NULL
          ELSE (
            SELECT id FROM namespaces
            WHERE id = regexp_replace(namespace_path, '(?:.*/)?([0-9]+)/$', '\\1')::bigint
            LIMIT 1
          )
        END AS namespace_id
      FROM (#{relation.to_sql}) AS rows
      ON CONFLICT (namespace_id, user_id, event, timestamp) DO NOTHING
      SQL
    end
  end

  def down
    # no-op due to data migration
  end
end
