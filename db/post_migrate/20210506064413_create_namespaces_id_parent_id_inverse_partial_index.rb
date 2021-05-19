# frozen_string_literal: true

class CreateNamespacesIdParentIdInversePartialIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  NAME = 'index_namespaces_id_parent_id_is_not_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespaces, :id, where: 'parent_id IS NOT NULL', name: NAME
  end

  def down
    remove_concurrent_index :namespaces, :id, name: NAME
  end
end
