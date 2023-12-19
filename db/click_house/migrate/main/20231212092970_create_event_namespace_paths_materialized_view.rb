# frozen_string_literal: true

class CreateEventNamespacePathsMaterializedView < ClickHouse::Migration
  def up
    # The path contains the same data as traversal_ids, ancestor namespace ids separated by
    # the / character. Here we extract the last id value from the path string and store it
    # as namespace id. Reasoning: batching over the table requires an integer column.
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS event_namespace_paths_mv
      TO event_namespace_paths
      AS
      SELECT
        splitByChar('/', path)[length(splitByChar('/', path)) - 1] AS namespace_id,
        path,
        argMax(deleted, events.updated_at) as deleted,
        max(events.updated_at) as last_event_at
      FROM events
      GROUP BY namespace_id, path
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS event_namespace_paths_mv
    SQL
  end
end
