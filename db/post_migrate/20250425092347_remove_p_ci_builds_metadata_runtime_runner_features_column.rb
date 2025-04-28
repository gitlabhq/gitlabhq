# frozen_string_literal: true

class RemovePCiBuildsMetadataRuntimeRunnerFeaturesColumn < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def up
    remove_column :p_ci_builds_metadata, :runtime_runner_features
  end

  def down
    add_column :p_ci_builds_metadata, :runtime_runner_features, :jsonb, null: false, default: {}
  end
end
