# frozen_string_literal: true

class AddTopicsNameGinIndex < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_topics_on_name_trigram'

  disable_ddl_transaction!

  def up
    add_concurrent_index :topics, :name, name: INDEX_NAME, using: :gin, opclass: { name: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name :topics, INDEX_NAME
  end
end
