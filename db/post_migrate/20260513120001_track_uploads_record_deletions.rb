# frozen_string_literal: true

class TrackUploadsRecordDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '19.0'

  def up
    return if has_loose_foreign_key?(:uploads)

    track_record_deletions_override_table_name(:uploads)
  end

  def down
    return unless has_loose_foreign_key?(:uploads)

    untrack_record_deletions(:uploads)
  end
end
