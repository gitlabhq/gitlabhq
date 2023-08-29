# frozen_string_literal: true

class CreateAsyncIndexForCiStagesPipelineId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_stages
  INDEXES = {
    'index_ci_stages_on_pipeline_id_convert_to_bigint_and_name' => [
      [:pipeline_id_convert_to_bigint, :name], { unique: true }
    ],
    'index_ci_stages_on_pipeline_id_convert_to_bigint' => [
      [:pipeline_id_convert_to_bigint], {}
    ],
    'index_ci_stages_on_pipeline_id_convert_to_bigint_and_id' => [
      [:pipeline_id_convert_to_bigint, :id], { where: 'status = ANY (ARRAY[0, 1, 2, 8, 9, 10])' }
    ],
    'index_ci_stages_on_pipeline_id_convert_to_bigint_and_position' => [
      [:pipeline_id_convert_to_bigint, :position], {}
    ]
  }

  def up
    INDEXES.each do |index_name, (columns, options)|
      prepare_async_index TABLE_NAME, columns, name: index_name, **options
    end
  end

  def down
    INDEXES.each do |index_name, (columns, options)|
      unprepare_async_index TABLE_NAME, columns, name: index_name, **options
    end
  end
end
