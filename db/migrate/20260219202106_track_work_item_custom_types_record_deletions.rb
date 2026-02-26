# frozen_string_literal: true

class TrackWorkItemCustomTypesRecordDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.10'

  def up
    track_record_deletions(:work_item_custom_types)
  end

  def down
    untrack_record_deletions(:work_item_custom_types)
  end
end
