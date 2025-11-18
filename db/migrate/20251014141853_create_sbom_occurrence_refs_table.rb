# frozen_string_literal: true

class CreateSbomOccurrenceRefsTable < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    create_table :sbom_occurrence_refs do |t|
      t.bigint :project_id, null: false
      t.bigint :sbom_occurrence_id, null: false
      t.bigint :security_project_tracked_context_id, null: false
      t.binary :commit_sha, null: false
      t.bigint :pipeline_id, null: true
    end
  end

  def down
    drop_table :sbom_occurrence_refs
  end
end
