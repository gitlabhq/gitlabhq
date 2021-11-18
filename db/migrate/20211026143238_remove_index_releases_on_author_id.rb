# frozen_string_literal: true

class RemoveIndexReleasesOnAuthorId < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_releases_on_author_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :releases, INDEX_NAME
  end

  def down
    add_concurrent_index :releases, [:author_id], name: INDEX_NAME
  end
end
