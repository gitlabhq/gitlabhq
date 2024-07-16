# frozen_string_literal: true

class AddIndexesToImportSourceUsers < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.3'

  STATUS_INDEX = 'index_import_source_users_on_namespace_id_and_status'
  NAMESPACE_INDEX = 'index_import_source_users_on_namespace_id'

  def up
    add_concurrent_index :import_source_users, [:namespace_id, :status], name: STATUS_INDEX

    remove_concurrent_index_by_name :import_source_users, name: NAMESPACE_INDEX
  end

  def down
    add_concurrent_index :import_source_users, [:namespace_id], name: NAMESPACE_INDEX

    remove_concurrent_index_by_name :import_source_users, name: STATUS_INDEX
  end
end
