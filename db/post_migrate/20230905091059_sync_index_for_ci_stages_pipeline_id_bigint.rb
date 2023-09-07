# frozen_string_literal: true

class SyncIndexForCiStagesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

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
      add_concurrent_index TABLE_NAME, columns, name: index_name, **options
    end
  end

  def down
    INDEXES.each do |index_name, (_columns, _options)|
      remove_concurrent_index_by_name TABLE_NAME, index_name
    end
  end
end
