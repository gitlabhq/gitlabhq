# frozen_string_literal: true

class AddReleasePublishedAtIndexToRelease < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  disable_ddl_transaction!

  def up
    add_concurrent_index :releases, :release_published_at, name: 'releases_published_at_index'
  end

  def down
    remove_concurrent_index :releases, :release_published_at, name: 'releases_published_at_index'
  end
end
