# frozen_string_literal: true

class UpdateIndexOnNamespacesForTypeAndId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_namespaces_on_type_partial'
  NEW_INDEX_NAME = 'index_namespaces_on_type_and_id_partial'

  def up
    add_concurrent_index(:namespaces, [:type, :id], where: 'type IS NOT NULL', name: NEW_INDEX_NAME)

    remove_concurrent_index_by_name(:namespaces, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(:namespaces, :type, where: 'type IS NOT NULL', name: OLD_INDEX_NAME)

    remove_concurrent_index_by_name(:namespaces, NEW_INDEX_NAME)
  end
end
