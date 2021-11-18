# frozen_string_literal: true

class AddRuntimeRunnerFeaturesToCiBuildsMetadata < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :ci_builds_metadata, :runtime_runner_features, :jsonb, default: {}, null: false
  end
end
