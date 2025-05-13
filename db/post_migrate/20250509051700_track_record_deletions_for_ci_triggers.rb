# frozen_string_literal: true

class TrackRecordDeletionsForCiTriggers < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.1'

  def up
    track_record_deletions(:ci_triggers)
  end

  def down
    untrack_record_deletions(:ci_triggers)
  end
end
