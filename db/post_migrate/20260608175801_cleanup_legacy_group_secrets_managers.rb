# frozen_string_literal: true

class CleanupLegacyGroupSecretsManagers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  STUCK_THRESHOLD = '1 hour'

  # See the project counterpart `CleanupLegacyProjectSecretsManagers`
  # for the full rationale; this migration is the same shape for the
  # group table.
  def up
    execute(<<~SQL)
      DELETE FROM group_secrets_managers WHERE group_id IS NULL
    SQL

    execute(<<~SQL)
      DELETE FROM group_secrets_managers
      WHERE status IN (0, 2)
        AND created_at < NOW() - INTERVAL '#{STUCK_THRESHOLD}'
    SQL
  end

  def down
    # No-op: cannot reconstruct deleted SMs.
  end
end
