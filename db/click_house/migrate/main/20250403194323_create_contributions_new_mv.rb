# frozen_string_literal: true

class CreateContributionsNewMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS contributions_new_mv
      TO contributions_new
      AS
      SELECT
        id,
        argMax(path, events_new.updated_at) as path,
        argMax(author_id, events_new.updated_at) as author_id,
        argMax(target_type, events_new.updated_at) as target_type,
        argMax(action, events_new.updated_at) as action,
        argMax(date(created_at), events_new.updated_at) as created_at,
        max(events_new.updated_at) as updated_at
      FROM events_new
      WHERE (("events_new"."action" IN (5, 6) AND "events_new"."target_type" = '')
        OR ("events_new"."action" IN (1, 3, 7, 12)
          AND "events_new"."target_type" IN ('MergeRequest', 'Issue', 'WorkItem')))
      GROUP BY id
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS contributions_new_mv
    SQL
  end
end
