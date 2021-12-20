# frozen_string_literal: true

class TrackDeletionsInNamespaces < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    track_record_deletions(:namespaces)
  end

  def down
    untrack_record_deletions(:namespaces)
  end
end
