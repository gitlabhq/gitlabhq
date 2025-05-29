# frozen_string_literal: true

class AddIndexToProjectComplianceViolationsNamespaceCreatedId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  INDEX_NAMESPACE_ID = 'idx_project_compliance_violations_on_namespace_id'
  INDEX_NAMESPACE_CREATED_AT_ID_DESC = 'i_project_compliance_violations_on_namespace_id_created_at_id'

  def up
    add_concurrent_index :project_compliance_violations, [:namespace_id, :created_at, :id],
      order: { created_at: :desc, id: :desc }, using: :btree, name: INDEX_NAMESPACE_CREATED_AT_ID_DESC

    remove_concurrent_index_by_name :project_compliance_violations, INDEX_NAMESPACE_ID
  end

  def down
    add_concurrent_index :project_compliance_violations, :namespace_id, name: INDEX_NAMESPACE_ID

    remove_concurrent_index_by_name :project_compliance_violations, INDEX_NAMESPACE_CREATED_AT_ID_DESC
  end
end
