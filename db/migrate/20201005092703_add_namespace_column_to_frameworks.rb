# frozen_string_literal: true

class AddNamespaceColumnToFrameworks < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'idx_on_compliance_management_frameworks_namespace_id_name'

  disable_ddl_transaction!

  def up
    unless column_exists?(:compliance_management_frameworks, :namespace_id)
      add_column(:compliance_management_frameworks, :namespace_id, :integer)
    end

    add_concurrent_foreign_key(:compliance_management_frameworks, :namespaces, column: :namespace_id, on_delete: :cascade)
    add_concurrent_index(:compliance_management_frameworks, [:namespace_id, :name], unique: true, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:compliance_management_frameworks, INDEX_NAME)
    remove_foreign_key_if_exists(:compliance_management_frameworks, :namespaces, column: :namespace_id)

    remove_column(:compliance_management_frameworks, :namespace_id)
  end
end
