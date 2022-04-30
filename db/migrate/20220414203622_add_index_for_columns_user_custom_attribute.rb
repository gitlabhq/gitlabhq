# frozen_string_literal: true

class AddIndexForColumnsUserCustomAttribute < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  INDEX_NAME = 'index_key_updated_at_on_user_custom_attribute'

  def up
    add_concurrent_index(:user_custom_attributes, [:key, :updated_at], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:user_custom_attributes, INDEX_NAME)
  end
end
