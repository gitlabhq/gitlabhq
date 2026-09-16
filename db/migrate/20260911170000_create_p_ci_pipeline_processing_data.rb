# frozen_string_literal: true

class CreatePCiPipelineProcessingData < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  TABLE_NAME = :p_ci_pipeline_processing_data
  PROJECT_INDEX_NAME = :idx_p_ci_pipeline_processing_data_on_project_id

  def change
    creation_options = {
      primary_key: [:pipeline_id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)',
      if_not_exists: true
    }

    create_table TABLE_NAME, **creation_options do |t|
      t.bigint :pipeline_id, null: false
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false
      t.boolean :interruptible_protected, null: false, default: false

      t.index :project_id, name: PROJECT_INDEX_NAME
    end
  end
end
