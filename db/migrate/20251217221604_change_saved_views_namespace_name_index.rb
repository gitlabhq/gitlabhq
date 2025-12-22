# frozen_string_literal: true

class ChangeSavedViewsNamespaceNameIndex < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  disable_ddl_transaction!

  INDEX_NAME = 'index_saved_views_on_namespace_id_and_name'

  def up
    remove_concurrent_index :saved_views, [:namespace_id, :name], name: INDEX_NAME
    add_concurrent_index :saved_views, [:namespace_id, :name], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :saved_views, [:namespace_id, :name], name: INDEX_NAME
    add_concurrent_index :saved_views, [:namespace_id, :name], unique: true, name: INDEX_NAME
  end
end
