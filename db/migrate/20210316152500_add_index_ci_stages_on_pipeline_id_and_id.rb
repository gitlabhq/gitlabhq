# frozen_string_literal: true

class AddIndexCiStagesOnPipelineIdAndId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_stages_on_pipeline_id_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_stages, %i[pipeline_id id], where: 'status IN (0, 1, 2, 8, 9, 10)', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_stages, INDEX_NAME
  end
end
