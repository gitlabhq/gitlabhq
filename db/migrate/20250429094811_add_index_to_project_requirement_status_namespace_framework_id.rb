# frozen_string_literal: true

class AddIndexToProjectRequirementStatusNamespaceFrameworkId < Gitlab::Database::Migration[2.3]
  milestone '18.0'
  disable_ddl_transaction!

  INDEX_NAMESPACE_FRAMEWORK_ID_DESC = 'i_project_requirement_statuses_on_namespace_id_framework_id'

  def up
    add_concurrent_index :project_requirement_compliance_statuses, [:namespace_id, :compliance_framework_id, :id],
      order: { compliance_framework_id: :asc, id: :asc }, using: :btree, name: INDEX_NAMESPACE_FRAMEWORK_ID_DESC
  end

  def down
    remove_concurrent_index_by_name :project_requirement_compliance_statuses, INDEX_NAMESPACE_FRAMEWORK_ID_DESC
  end
end
