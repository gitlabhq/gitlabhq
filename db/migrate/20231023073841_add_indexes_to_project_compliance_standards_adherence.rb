# frozen_string_literal: true

class AddIndexesToProjectComplianceStandardsAdherence < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAMESPACE_ID = 'index_project_compliance_standards_adherence_on_namespace_id'
  INDEX_NAMESPACE_AND_PROJECT_ID_DESC = 'i_compliance_standards_adherence_on_namespace_id_and_proj_id'

  def up
    add_concurrent_index :project_compliance_standards_adherence, [:namespace_id, :project_id, :id],
      order: { project_id: :desc, id: :desc }, using: :btree, name: INDEX_NAMESPACE_AND_PROJECT_ID_DESC

    remove_concurrent_index_by_name :project_compliance_standards_adherence, INDEX_NAMESPACE_ID
  end

  def down
    add_concurrent_index :project_compliance_standards_adherence, :namespace_id, name: INDEX_NAMESPACE_ID

    remove_concurrent_index_by_name :project_compliance_standards_adherence, INDEX_NAMESPACE_AND_PROJECT_ID_DESC
  end
end
