# frozen_string_literal: true

class AddIndexNamespaceHostnameImportTypeToImportSourceUsers < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  INDEX_NAME = 'idx_namespace_hostname_import_type_id_source_name_and_username'

  def up
    add_concurrent_index :import_source_users, [:namespace_id, :source_hostname, :import_type, :id], name: INDEX_NAME,
      where: 'source_name IS NULL OR source_username IS NULL'
  end

  def down
    remove_concurrent_index_by_name :import_source_users, INDEX_NAME
  end
end
