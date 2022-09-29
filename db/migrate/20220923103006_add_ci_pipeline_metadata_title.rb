# frozen_string_literal: true

class AddCiPipelineMetadataTitle < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    create_table :ci_pipeline_metadata, id: false do |t|
      t.bigint :project_id, null: false

      t.references :pipeline,
                   null: false,
                   primary_key: true,
                   default: nil,
                   index: false,
                   foreign_key: { to_table: :ci_pipelines, on_delete: :cascade }

      t.text :title, null: false, limit: 255

      t.index [:pipeline_id, :title], name: 'index_ci_pipeline_metadata_on_pipeline_id_title'
      t.index [:project_id], name: 'index_ci_pipeline_metadata_on_project_id'
    end
  end

  def down
    drop_table :ci_pipeline_metadata
  end
end
