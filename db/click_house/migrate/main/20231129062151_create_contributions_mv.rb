# frozen_string_literal: true

class CreateContributionsMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS contributions_mv
      TO contributions
      AS
      SELECT
        id,
        argMax(path, events.updated_at) as path,
        argMax(author_id, events.updated_at) as author_id,
        argMax(target_type, events.updated_at) as target_type,
        argMax(action, events.updated_at) as action,
        argMax(date(created_at), events.updated_at) as created_at,
        max(events.updated_at) as updated_at
      FROM events
      WHERE (("events"."action" IN (5, 6) AND "events"."target_type" = '')
        OR ("events"."action" IN (1, 3, 7, 12)
          AND "events"."target_type" IN ('MergeRequest', 'Issue', 'WorkItem')))
      GROUP BY id
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS contributions_mv
    SQL
  end
end
