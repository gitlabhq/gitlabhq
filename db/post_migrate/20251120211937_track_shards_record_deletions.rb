# frozen_string_literal: true

class TrackShardsRecordDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.7'

  def up
    track_record_deletions(:shards)
  end

  def down
    untrack_record_deletions(:shards)
  end
end
