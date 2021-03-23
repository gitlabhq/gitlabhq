# frozen_string_literal: true

class SetTraversalIdsForGitlabOrgGroupStaging < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless Gitlab.staging?

    # namespace ID 9970 is gitlab-org on staging.
    with_lock_retries do
      execute(<<~SQL)
        UPDATE
          namespaces
        SET
          traversal_ids = cte.traversal_ids
        FROM
          (
            WITH RECURSIVE cte(id, traversal_ids, cycle) AS (
              VALUES
                (9970, ARRAY[9970], false)
              UNION ALL
              SELECT
                n.id,
                cte.traversal_ids || n.id,
                n.id = ANY(cte.traversal_ids)
              FROM
                namespaces n,
                cte
              WHERE
                n.parent_id = cte.id
                AND NOT cycle
            )
            SELECT
              id,
              traversal_ids
            FROM
              cte FOR
            UPDATE
              ) as cte
        WHERE
          namespaces.id = cte.id
          AND namespaces.traversal_ids <> cte.traversal_ids
      SQL
    end
  end

  def down
    return unless Gitlab.staging?

    # namespace ID 9970 is gitlab-org on staging.
    with_lock_retries do
      execute(<<~SQL)
        UPDATE
          namespaces
        SET
          traversal_ids = '{}'
        FROM
          (
            WITH RECURSIVE cte(id, traversal_ids, cycle) AS (
              VALUES
                (9970, ARRAY[9970], false)
              UNION ALL
              SELECT
                n.id,
                cte.traversal_ids || n.id,
                n.id = ANY(cte.traversal_ids)
              FROM
                namespaces n,
                cte
              WHERE
                n.parent_id = cte.id
                AND NOT cycle
            )
            SELECT
              id,
              traversal_ids
            FROM
              cte FOR
            UPDATE
              ) as cte
        WHERE
          namespaces.id = cte.id
      SQL
    end
  end
end
