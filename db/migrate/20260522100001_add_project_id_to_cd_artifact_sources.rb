# frozen_string_literal: true

class AddProjectIdToCdArtifactSources < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :cd_artifact_sources, :project_id, :bigint
  end
end
