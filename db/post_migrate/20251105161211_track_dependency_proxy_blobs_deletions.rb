# frozen_string_literal: true

class TrackDependencyProxyBlobsDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.6'

  def up
    track_record_deletions(:dependency_proxy_blobs)
  end

  def down
    untrack_record_deletions(:dependency_proxy_blobs)
  end
end
