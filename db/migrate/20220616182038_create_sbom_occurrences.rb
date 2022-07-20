# frozen_string_literal: true

class CreateSbomOccurrences < Gitlab::Database::Migration[2.0]
  def change
    create_table :sbom_occurrences do |t|
      t.timestamps_with_timezone
      t.bigint :component_version_id, null: false, index: true
      t.bigint :project_id, null: false, index: true
      t.bigint :pipeline_id, index: true
      t.bigint :source_id, index: true
      t.binary :commit_sha, null: false
    end
  end
end
