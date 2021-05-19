# frozen_string_literal: true

class CreateElasticReindexingSlices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  class ReindexingSubtask < ActiveRecord::Base
    self.table_name = 'elastic_reindexing_subtasks'
  end

  class ReindexingSlice < ActiveRecord::Base
    self.table_name = 'elastic_reindexing_slices'
  end

  def up
    unless table_exists?(:elastic_reindexing_slices)
      create_table_with_constraints :elastic_reindexing_slices do |t|
        t.timestamps_with_timezone null: false
        t.references :elastic_reindexing_subtask, foreign_key: { on_delete: :cascade }, null: false, index: { name: 'idx_elastic_reindexing_slices_on_elastic_reindexing_subtask_id' }
        t.integer :elastic_slice, null: false, limit: 2, default: 0
        t.integer :elastic_max_slice, null: false, limit: 2, default: 0
        t.integer :retry_attempt, null: false, limit: 2, default: 0
        t.text :elastic_task

        t.text_limit :elastic_task, 255
      end
    end

    ReindexingSubtask.find_each do |subtask|
      next if ReindexingSlice.where(elastic_reindexing_subtask_id: subtask.id).exists?

      ReindexingSlice.create(
        elastic_reindexing_subtask_id: subtask.id,
        elastic_task: subtask.elastic_task,
        retry_attempt: 0
      )
    end
  end

  def down
    drop_table :elastic_reindexing_slices
  end
end
