# frozen_string_literal: true

class SyncIndexForCiSourcesPipelinesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

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
      add_concurrent_index TABLE_NAME, columns, name: index_name, **options
    end
  end

  def down
    INDEXES.each do |index_name, (_columns, _options)|
      remove_concurrent_index_by_name TABLE_NAME, index_name
    end
  end
end
