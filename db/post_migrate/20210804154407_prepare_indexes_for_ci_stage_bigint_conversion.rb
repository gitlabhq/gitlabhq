# frozen_string_literal: true

class PrepareIndexesForCiStageBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    prepare_async_index :ci_stages, :id_convert_to_bigint, unique: true,
      name: :index_ci_stages_on_id_convert_to_bigint

    prepare_async_index :ci_stages, [:pipeline_id, :id_convert_to_bigint], where: 'status in (0, 1, 2, 8, 9, 10)',
      name: :index_ci_stages_on_pipeline_id_and_id_convert_to_bigint
  end

  def down
    unprepare_async_index_by_name :ci_stages, :index_ci_stages_on_pipeline_id_and_id_convert_to_bigint

    unprepare_async_index_by_name :ci_stages, :index_ci_stages_on_id_convert_to_bigint
  end
end
