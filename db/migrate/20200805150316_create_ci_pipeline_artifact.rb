# frozen_string_literal: true

class CreateCiPipelineArtifact < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:ci_pipeline_artifacts)
      create_table :ci_pipeline_artifacts do |t|
        t.timestamps_with_timezone
        t.bigint :pipeline_id, null: false, index: true
        t.bigint :project_id, null: false, index: true
        t.integer :size, null: false
        t.integer :file_store, null: false, limit: 2
        t.integer :file_type, null: false, limit: 2
        t.integer :file_format, null: false, limit: 2
        t.text :file

        t.index [:pipeline_id, :file_type], unique: true
      end
    end

    add_text_limit :ci_pipeline_artifacts, :file, 255
  end

  def down
    drop_table :ci_pipeline_artifacts
  end
end
