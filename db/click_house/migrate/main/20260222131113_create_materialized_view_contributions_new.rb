# frozen_string_literal: true

class CreateMaterializedViewContributionsNew < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW contributions_new_mv
      TO contributions_new
      AS
      WITH
        base AS (SELECT * FROM siphon_events
        WHERE
          (
            (
            action IN (5, 6) AND target_type = ''
            )
            OR
            (
               action IN (1, 3, 7, 12) AND
               target_type IN ('MergeRequest', 'Issue', 'WorkItem')
            )
          )
        )
      SELECT
        base.id AS id,
        base.path AS path,
        base.author_id AS author_id,
        base.target_type AS target_type,
        base.action AS action,
        base.created_at AS created_at,
        base.updated_at AS updated_at,
        base._siphon_replicated_at AS version,
        base._siphon_deleted AS deleted
      FROM base
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS contributions_new_mv'
  end
end
