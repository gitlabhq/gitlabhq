# frozen_string_literal: true

class AddIndexToProjectRequirementStatusNamesapceUpdatedId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAMESPACE_ID = 'idx_project_requirement_statuses_on_namespace_id'
  INDEX_NAMESPACE_UPDATED_AT_ID_DESC = 'i_project_requirement_statuses_on_namespace_id_updated_at_id'

  def up
    add_concurrent_index :project_requirement_compliance_statuses, [:namespace_id, :updated_at, :id],
      order: { updated_at: :desc, id: :desc }, using: :btree, name: INDEX_NAMESPACE_UPDATED_AT_ID_DESC

    remove_concurrent_index_by_name :project_requirement_compliance_statuses, INDEX_NAMESPACE_ID
  end

  def down
    add_concurrent_index :project_requirement_compliance_statuses, :namespace_id, name: INDEX_NAMESPACE_ID

    remove_concurrent_index_by_name :project_requirement_compliance_statuses, INDEX_NAMESPACE_UPDATED_AT_ID_DESC
  end
end
