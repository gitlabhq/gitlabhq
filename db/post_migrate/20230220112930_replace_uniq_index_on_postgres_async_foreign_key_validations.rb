# frozen_string_literal: true

class ReplaceUniqIndexOnPostgresAsyncForeignKeyValidations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'unique_postgres_async_fk_validations_name_and_table_name'
  OLD_INDEX_NAME = 'index_postgres_async_foreign_key_validations_on_name'
  TABLE_NAME = 'postgres_async_foreign_key_validations'

  def up
    add_concurrent_index TABLE_NAME, [:name, :table_name], unique: true, name: NEW_INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :name, unique: true, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, NEW_INDEX_NAME
  end
end
