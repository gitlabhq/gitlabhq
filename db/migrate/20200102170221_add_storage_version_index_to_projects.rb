# frozen_string_literal: true

class AddStorageVersionIndexToProjects < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, :id, where: 'storage_version < 2 or storage_version IS NULL', name: 'index_on_id_partial_with_legacy_storage'
  end

  def down
    remove_concurrent_index :projects, :id, where: 'storage_version < 2 or storage_version IS NULL', name: 'index_on_id_partial_with_legacy_storage'
  end
end
