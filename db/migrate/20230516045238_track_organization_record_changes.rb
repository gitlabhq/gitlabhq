# frozen_string_literal: true

class TrackOrganizationRecordChanges < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    track_record_deletions(:organizations)
  end

  def down
    untrack_record_deletions(:organizations)
  end
end
