# frozen_string_literal: true

class CleanupLegacyProjectSecretsManagers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  STUCK_THRESHOLD = '1 hour'

  # Cleans up legacy `project_secrets_managers` rows that the trigger
  # pivot (see https://gitlab.com/gitlab-org/gitlab/-/issues/600290)
  # leaves behind:
  #
  # 1. Orphans (`project_id IS NULL`). Removing them is required
  #    before the NOT NULL migration later in this MR can succeed.
  #    Backfilling `project_id` from the cached path would violate
  #    the FK on `project_secrets_managers.project_id` (now `ON
  #    DELETE CASCADE` after !239582), since the original project is
  #    already gone. The trigger's `OLD.project_id IS NULL` guard
  #    skips them too, so no deprovision task is created. Orphan
  #    OpenBao cleanup is the reaper's responsibility long-term
  #    (gitlab-org/gitlab#600120).
  #
  # 2. Stuck SMs in `:provisioning` (0) or `:deprovisioning` (2)
  #    past `STUCK_THRESHOLD`. Each DELETE fires the AFTER DELETE
  #    trigger installed by !239582, which inserts a deprovision
  #    maintenance task carrying the snapshot ids; the cron worker
  #    tears down OpenBao state.
  def up
    execute(<<~SQL)
      DELETE FROM project_secrets_managers WHERE project_id IS NULL
    SQL

    execute(<<~SQL)
      DELETE FROM project_secrets_managers
      WHERE status IN (0, 2)
        AND created_at < NOW() - INTERVAL '#{STUCK_THRESHOLD}'
    SQL
  end

  def down
    # No-op: cannot reconstruct deleted SMs.
  end
end
