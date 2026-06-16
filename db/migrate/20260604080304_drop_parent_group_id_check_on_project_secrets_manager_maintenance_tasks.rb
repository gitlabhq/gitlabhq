# frozen_string_literal: true

class DropParentGroupIdCheckOnProjectSecretsManagerMaintenanceTasks < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  # See https://gitlab.com/gitlab-org/gitlab/-/issues/600371. `parent_group_id`
  # is denormalized but unused (3-level OpenBao path uses root_namespace_id
  # at level 2). Drop the NOT NULL check first so the new application code
  # can stop populating it; the column drop follows in a post-deploy
  # migration once `ignore_column` has rolled out.
  def up
    remove_not_null_constraint :project_secrets_manager_maintenance_tasks, :parent_group_id
  end

  # Down is intentionally a no-op. Once the app has been deployed without
  # the NOT NULL constraint, new rows may have `parent_group_id = NULL`,
  # so re-adding the constraint would fail validation. The forward
  # direction is what matters; a clean rollback would have to backfill or
  # delete those rows first, which doesn't belong in a schema migration.
  # See https://docs.gitlab.com/development/database/not_null_constraints/#dropping-a-not-null-constraint-on-a-column-in-an-existing-table.
  def down; end
end
