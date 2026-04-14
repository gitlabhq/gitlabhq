# frozen_string_literal: true

class AddUpdatedByIdIndexOnSavedViews < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_saved_views_on_updated_by_id'

  milestone '18.11'

  disable_ddl_transaction!

  def up
    add_concurrent_index :saved_views, :updated_by_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :saved_views, INDEX_NAME
  end
end
