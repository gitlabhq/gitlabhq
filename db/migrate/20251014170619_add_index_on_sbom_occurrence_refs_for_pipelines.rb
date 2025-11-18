# frozen_string_literal: true

class AddIndexOnSbomOccurrenceRefsForPipelines < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_occurrence_refs, :pipeline_id
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrence_refs, :pipeline_id
  end
end
