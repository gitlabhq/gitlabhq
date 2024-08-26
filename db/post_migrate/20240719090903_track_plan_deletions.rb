# frozen_string_literal: true

class TrackPlanDeletions < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '17.4'

  enable_lock_retries!

  def up
    track_record_deletions(:plans)
  end

  def down
    untrack_record_deletions(:plans)
  end
end
