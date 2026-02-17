# frozen_string_literal: true

class TrackProjectRepositoryRecordChanges < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.9'

  def up
    track_record_deletions(:project_repositories)
  end

  def down
    untrack_record_deletions(:project_repositories)
  end
end
