# frozen_string_literal: true

class TrackCiSecureFilesDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.6'

  def up
    track_record_deletions(:ci_secure_files)
  end

  def down
    untrack_record_deletions(:ci_secure_files)
  end
end
