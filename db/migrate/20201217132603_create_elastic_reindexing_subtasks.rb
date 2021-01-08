# frozen_string_literal: true

class CreateElasticReindexingSubtasks < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class ReindexingTask < ActiveRecord::Base
    self.table_name = 'elastic_reindexing_tasks'
  end

  class ReindexingSubtask < ActiveRecord::Base
    self.table_name = 'elastic_reindexing_subtasks'
  end

  def up
    unless table_exists?(:elastic_reindexing_subtasks)
      create_table :elastic_reindexing_subtasks do |t|
        t.references :elastic_reindexing_task, foreign_key: { on_delete: :cascade }, null: false
        t.text :alias_name, null: false
        t.text :index_name_from, null: false
        t.text :index_name_to, null: false
        t.text :elastic_task, null: false
        t.integer :documents_count_target
        t.integer :documents_count
        t.timestamps_with_timezone null: false
      end
    end

    add_text_limit :elastic_reindexing_subtasks, :index_name_from, 255
    add_text_limit :elastic_reindexing_subtasks, :index_name_to, 255
    add_text_limit :elastic_reindexing_subtasks, :elastic_task, 255
    add_text_limit :elastic_reindexing_subtasks, :alias_name, 255

    ReindexingTask.find_each do |task|
      next if task.index_name_from.blank? || task.index_name_to.blank? || task.elastic_task.blank?
      next if ReindexingSubtask.where(elastic_reindexing_task_id: task.id).exists?

      ReindexingSubtask.create(
        elastic_reindexing_task_id: task.id,
        documents_count_target: task.documents_count_target,
        documents_count: task.documents_count,
        alias_name: 'gitlab-production',
        index_name_from: task.index_name_from,
        index_name_to: task.index_name_to,
        elastic_task: task.elastic_task
      )
    end
  end

  def down
    drop_table :elastic_reindexing_subtasks
  end
end
