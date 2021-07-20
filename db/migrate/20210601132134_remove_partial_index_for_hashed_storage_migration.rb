# frozen_string_literal: true

class RemovePartialIndexForHashedStorageMigration < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    remove_concurrent_index :projects, :id, name: 'index_on_id_partial_with_legacy_storage'
  end

  def down
    add_concurrent_index :projects, :id, where: 'storage_version < 2 or storage_version IS NULL', name: 'index_on_id_partial_with_legacy_storage'
  end
end
