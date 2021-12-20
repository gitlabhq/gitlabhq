# frozen_string_literal: true

class TrackCiPipelineDeletions < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    track_record_deletions(:ci_pipelines)
  end

  def down
    untrack_record_deletions(:ci_pipelines)
  end
end
