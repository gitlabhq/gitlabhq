# frozen_string_literal: true

class RemoveRedundantTaggingsIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = :index_taggings_on_taggable_id_and_taggable_type

  def up
    remove_concurrent_index_by_name :taggings, INDEX_NAME
  end

  def down
    add_concurrent_index :taggings, [:taggable_id, :taggable_type], name: INDEX_NAME
  end
end
