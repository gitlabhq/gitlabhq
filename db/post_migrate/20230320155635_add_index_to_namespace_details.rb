# frozen_string_literal: true

class AddIndexToNamespaceDetails < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_fuc_over_limit_notified_at'
  TABLE_NAME = 'namespace_details'
  COLUMN_NAME = 'free_user_cap_over_limit_notified_at'

  def up
    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
  end
end
