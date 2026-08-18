# frozen_string_literal: true

class BackfillCdRolloutsIid < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  # Numbers only the NULL rows (rollouts predating the column), starting after each
  # application's current max iid so they can't collide with values already handed out,
  # then re-syncs each application's counter. Data volume is tiny (pre-release), so a
  # single UPDATE is used rather than a batched background migration.
  def up
    connection.execute(<<~SQL)
      WITH offsets AS (
        SELECT application_id, COALESCE(MAX(iid), 0) AS base
        FROM cd_rollouts
        GROUP BY application_id
      ),
      numbered AS (
        SELECT id, application_id,
               row_number() OVER (PARTITION BY application_id ORDER BY id) AS rn
        FROM cd_rollouts
        WHERE iid IS NULL
      )
      UPDATE cd_rollouts r
      SET iid = o.base + n.rn
      FROM numbered n
      JOIN offsets o ON o.application_id = n.application_id
      WHERE r.id = n.id
    SQL

    connection.execute(<<~SQL)
      UPDATE cd_applications a
      SET last_rollout_iid = COALESCE(
        (SELECT MAX(iid) FROM cd_rollouts WHERE application_id = a.id), 0
      )
    SQL
  end

  def down
    # No-op: nothing to reverse.
  end
end
