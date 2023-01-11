# frozen_string_literal: true

class AddQueryIndexForCiPipelineSchedules < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_pipeline_schedules
  INDEX_NAME = :index_ci_pipeline_schedules_on_id_and_next_run_at_and_active
  COLUMNS = %i[id next_run_at].freeze
  INDEX_CONDITION = 'active = TRUE'

  disable_ddl_transaction!

  def up
    add_concurrent_index(TABLE_NAME, COLUMNS, name: INDEX_NAME, where: INDEX_CONDITION)
  end

  def down
    remove_concurrent_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end
end
