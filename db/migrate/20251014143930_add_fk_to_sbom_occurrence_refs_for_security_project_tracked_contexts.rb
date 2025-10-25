# frozen_string_literal: true

class AddFkToSbomOccurrenceRefsForSecurityProjectTrackedContexts < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_occurrence_refs,
      :security_project_tracked_context_id,
      name: 'idx_sbom_occurrence_refs_on_sec_prj_trck_cnxt_id'
    add_concurrent_foreign_key :sbom_occurrence_refs,
      :security_project_tracked_contexts,
      column: :security_project_tracked_context_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :sbom_occurrence_refs, column: :security_project_tracked_context_id
    end
    remove_concurrent_index_by_name :sbom_occurrence_refs, 'idx_sbom_occurrence_refs_on_sec_prj_trck_cnxt_id'
  end
end
