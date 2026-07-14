# frozen_string_literal: true

class RemoveSessionArtifactsExactlyOneShardingConstraint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :duo_workflow_session_artifacts

  # `namespace_id` becomes the single sharding key and is backfilled to
  # `project.project_namespace_id` for project rows, so project rows will carry
  # BOTH `project_id` and `namespace_id`. The old `num_nonnulls(...) = 1`
  # (exactly-one) constraint is therefore removed. A `namespace_id IS NOT NULL`
  # constraint is added in a later post-deployment migration once the backfill
  # has run.
  def up
    remove_multi_column_not_null_constraint(TABLE_NAME, :project_id, :namespace_id)
  end

  def down
    # Re-add the validated constraint so a full ordered rollback restores
    # db/structure.sql exactly (a NOT VALID constraint would dump as a separate
    # ALTER and fail the db:check-migrations job). This is safe because the
    # backfill migration's own `down` runs first in an ordered rollback and nulls
    # `namespace_id` on project rows, restoring the exactly-one invariant.
    add_multi_column_not_null_constraint(TABLE_NAME, :project_id, :namespace_id)
  end
end
