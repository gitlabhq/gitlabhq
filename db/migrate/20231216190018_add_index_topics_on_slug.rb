# frozen_string_literal: true

class AddIndexTopicsOnSlug < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  INDEX_NAME = 'index_topics_on_slug'

  def up
    add_concurrent_index :topics, :slug, unique: true, where: 'slug IS NOT NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :topics, name: INDEX_NAME
  end
end
