# frozen_string_literal: true

class RemoveNotNullCiJobArtifactsConstraint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE ci_job_artifacts DROP CONSTRAINT IF EXISTS ci_job_artifacts_file_store_not_null;
      SQL
    end
  end

  def down
    # No-op
  end
end
