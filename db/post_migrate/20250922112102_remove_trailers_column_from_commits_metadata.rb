# frozen_string_literal: true

class RemoveTrailersColumnFromCommitsMetadata < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    remove_column :merge_request_commits_metadata, :trailers
  end

  def down
    add_column :merge_request_commits_metadata, :trailers, :jsonb, default: {}, null: false
  end
end
