# frozen_string_literal: true

class AddHasExposedArtifactsToCiBuildsMetadata < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    add_column :ci_builds_metadata, :has_exposed_artifacts, :boolean
  end

  def down
    remove_column :ci_builds_metadata, :has_exposed_artifacts
  end
end
