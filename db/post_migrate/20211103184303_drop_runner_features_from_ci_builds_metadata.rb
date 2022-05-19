# frozen_string_literal: true

class DropRunnerFeaturesFromCiBuildsMetadata < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    remove_column :ci_builds_metadata, :runner_features
  end

  def down
    add_column :ci_builds_metadata, :runner_features, :jsonb, default: {}, null: false
  end
end
