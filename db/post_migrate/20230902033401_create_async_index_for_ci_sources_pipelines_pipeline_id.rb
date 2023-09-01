# frozen_string_literal: true

class CreateAsyncIndexForCiSourcesPipelinesPipelineId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_sources_pipelines
  INDEXES = {
    'index_ci_sources_pipelines_on_pipeline_id_bigint' => [
      [:pipeline_id_convert_to_bigint], {}
    ],
    'index_ci_sources_pipelines_on_source_pipeline_id_bigint' => [
      [:source_pipeline_id_convert_to_bigint], {}
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
