# frozen_string_literal: true

class AddIndexesToMergeRequestComplianceViolations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_SEVERITY_LEVEL_DESC = 'i_compliance_violations_on_project_id_severity_and_id'
  INDEX_REASON_ASC = 'i_compliance_violations_on_project_id_reason_and_id'
  INDEX_TITLE_ASC = 'i_compliance_violations_on_project_id_title_and_id'
  INDEX_MERGED_AT_ASC = 'i_compliance_violations_on_project_id_merged_at_and_id'

  def up
    add_concurrent_index :merge_requests_compliance_violations, [:target_project_id, :severity_level, :id],
      order: { severity_level: :desc, id: :desc }, using: :btree, name: INDEX_SEVERITY_LEVEL_DESC
    add_concurrent_index :merge_requests_compliance_violations, [:target_project_id, :reason, :id],
      order: { reason: :asc, id: :asc }, using: :btree, name: INDEX_REASON_ASC
    add_concurrent_index :merge_requests_compliance_violations, [:target_project_id, :title, :id],
      order: { title: :asc, id: :asc }, using: :btree, name: INDEX_TITLE_ASC
    add_concurrent_index :merge_requests_compliance_violations, [:target_project_id, :merged_at, :id],
      order: { merged_at: :asc, id: :asc }, using: :btree, name: INDEX_MERGED_AT_ASC
  end

  def down
    remove_concurrent_index_by_name :merge_requests_compliance_violations, INDEX_TITLE_ASC
    remove_concurrent_index_by_name :merge_requests_compliance_violations, INDEX_TITLE_ASC
    remove_concurrent_index_by_name :merge_requests_compliance_violations, INDEX_SEVERITY_LEVEL_DESC
    remove_concurrent_index_by_name :merge_requests_compliance_violations, INDEX_REASON_ASC
    remove_concurrent_index_by_name :merge_requests_compliance_violations, INDEX_MERGED_AT_ASC
  end
end
