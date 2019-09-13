# frozen_string_literal: true

class ExcludeNullsFromIndexOnNamespacesType < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:namespaces, :type, where: 'type is not null', name: 'index_namespaces_on_type_partial')
    remove_concurrent_index_by_name(:namespaces, 'index_namespaces_on_type')
  end

  def down
    add_concurrent_index(:namespaces, :type, name: 'index_namespaces_on_type')
    remove_concurrent_index_by_name(:namespaces, 'index_namespaces_on_type_partial')
  end
end
