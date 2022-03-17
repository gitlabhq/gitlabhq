# frozen_string_literal: true

class CreateProjectBuildArtifactsSizeRefresh < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  CREATED_STATE = 1

  def change
    create_table :project_build_artifacts_size_refreshes do |t|
      t.references :project, index: { unique: true }, foreign_key: { on_delete: :cascade }, null: false
      t.bigint :last_job_artifact_id, null: true
      t.integer :state, null: false, default: CREATED_STATE, limit: 1
      t.datetime_with_timezone :refresh_started_at, null: true
      t.timestamps_with_timezone null: false

      # We will use this index for 2 purposes:
      # - for finding rows with state = :waiting
      # - for finding rows with state = :running and updated_at < x.days.ago
      #   which we can use to find jobs that were not able to complete and considered
      #   stale so we can retry
      t.index [:state, :updated_at], name: 'idx_build_artifacts_size_refreshes_state_updated_at'
    end
  end
end
