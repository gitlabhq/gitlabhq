# frozen_string_literal: true

class AddSourceTypeToCdArtifactSources < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :cd_artifact_sources, :source_type, :integer, limit: 2, null: false, default: 0
  end
end
