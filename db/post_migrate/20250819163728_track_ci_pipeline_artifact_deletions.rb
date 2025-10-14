# frozen_string_literal: true

class TrackCiPipelineArtifactDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.5'

  def up
    track_record_deletions(:ci_pipeline_artifacts)
  end

  def down
    untrack_record_deletions(:ci_pipeline_artifacts)
  end
end
