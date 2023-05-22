# frozen_string_literal: true

class AddIndexOnUserIdToImportFailures < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_import_failures_on_user_id_not_null'

  def up
    add_concurrent_index :import_failures, :user_id, where: 'user_id IS NOT NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :import_failures, INDEX_NAME
  end
end
