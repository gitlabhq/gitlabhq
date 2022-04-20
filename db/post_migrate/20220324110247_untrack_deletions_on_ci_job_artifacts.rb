# frozen_string_literal: true

class UntrackDeletionsOnCiJobArtifacts < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    untrack_record_deletions(:ci_job_artifacts)
  end

  def down
    track_record_deletions(:ci_job_artifacts)
  end
end
