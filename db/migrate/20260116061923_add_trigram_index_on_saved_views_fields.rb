# frozen_string_literal: true

class AddTrigramIndexOnSavedViewsFields < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  INDEX_NAME_TRIGRAM = 'index_saved_views_on_name_trigram'
  INDEX_DESCRIPTION_TRIGRAM = 'index_saved_views_on_description_trigram'

  def up
    add_concurrent_index :saved_views, :name, name: INDEX_NAME_TRIGRAM, using: :gin, opclass: { name: :gin_trgm_ops }

    add_concurrent_index :saved_views, :description, name: INDEX_DESCRIPTION_TRIGRAM, using: :gin,
      opclass: { description: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name :saved_views, INDEX_NAME_TRIGRAM
    remove_concurrent_index_by_name :saved_views, INDEX_DESCRIPTION_TRIGRAM
  end
end
