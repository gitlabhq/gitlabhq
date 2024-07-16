# frozen_string_literal: true

class DropIndexCiStageOnPipelineId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers

  milestone '17.2'
  disable_ddl_transaction!

  TABLE_NAME = :p_ci_stages
  INDEX_NAME = :p_ci_stages_pipeline_id_idx
  COLUM_NAME = :pipeline_id

  def up
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, index_name_for(TABLE_NAME, COLUM_NAME))
  end

  def down
    add_concurrent_partitioned_index(TABLE_NAME, COLUM_NAME, name: INDEX_NAME)
    rename_index(:ci_stages, :index_788357c6f1, :index_ci_stages_on_pipeline_id)
  end

  private

  def index_name_for(table, column)
    columns = Array.wrap(column.to_s)
    index = indexes(table).find { |i| i.columns == columns }
    index.name
  end
end
