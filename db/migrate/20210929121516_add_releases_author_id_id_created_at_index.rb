# frozen_string_literal: true
class AddReleasesAuthorIdIdCreatedAtIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_releases_on_author_id_id_created_at'

  def up
    add_concurrent_index :releases, [:author_id, :id, :created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :releases, INDEX_NAME
  end
end
