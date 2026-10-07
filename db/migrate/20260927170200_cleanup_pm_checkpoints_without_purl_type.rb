# frozen_string_literal: true

class CleanupPmCheckpointsWithoutPurlType < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_pm
  milestone '19.5'

  def up
    # no-op - this migration is required to allow a rollback of DropNotNullConstraintFromPmCheckpointsPurlType
  end

  def down
    execute('DELETE FROM pm_checkpoints WHERE purl_type IS NULL')
  end
end
