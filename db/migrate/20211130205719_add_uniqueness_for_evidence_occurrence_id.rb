# frozen_string_literal: true

class AddUniquenessForEvidenceOccurrenceId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'finding_evidences_on_vulnerability_occurrence_id'
  UNIQUE_INDEX_NAME = 'finding_evidences_on_unique_vulnerability_occurrence_id'

  def up
    add_concurrent_index :vulnerability_finding_evidences, [:vulnerability_occurrence_id], unique: true, name: UNIQUE_INDEX_NAME
    remove_concurrent_index :vulnerability_finding_evidences, [:vulnerability_occurrence_id], name: INDEX_NAME
  end

  def down
    add_concurrent_index :vulnerability_finding_evidences, [:vulnerability_occurrence_id], name: INDEX_NAME
    remove_concurrent_index :vulnerability_finding_evidences, [:vulnerability_occurrence_id], name: UNIQUE_INDEX_NAME
  end
end
