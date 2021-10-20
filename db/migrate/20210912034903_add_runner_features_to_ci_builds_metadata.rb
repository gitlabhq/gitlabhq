# frozen_string_literal: true

class AddRunnerFeaturesToCiBuildsMetadata < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :ci_builds_metadata, :runner_features, :jsonb, default: {}, null: false
  end
end
