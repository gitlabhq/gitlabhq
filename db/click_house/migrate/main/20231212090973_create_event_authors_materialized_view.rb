# frozen_string_literal: true

class CreateEventAuthorsMaterializedView < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS event_authors_mv
      TO event_authors
      AS
      SELECT
        author_id,
        argMax(deleted, events.updated_at) as deleted,
        max(events.updated_at) as last_event_at
      FROM events
      GROUP BY author_id
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS event_authors_mv
    SQL
  end
end
