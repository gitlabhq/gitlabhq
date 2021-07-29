# frozen_string_literal: true

class RemoveUnusedColumnsFromElasticReindexingTasks < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    remove_column :elastic_reindexing_tasks, :documents_count, :integer
    remove_column :elastic_reindexing_tasks, :index_name_from, :text
    remove_column :elastic_reindexing_tasks, :index_name_to, :text
    remove_column :elastic_reindexing_tasks, :elastic_task, :text
    remove_column :elastic_reindexing_tasks, :documents_count_target, :integer
  end

  def down
    add_column :elastic_reindexing_tasks, :documents_count, :integer
    add_column :elastic_reindexing_tasks, :index_name_from, :text
    add_column :elastic_reindexing_tasks, :index_name_to, :text
    add_column :elastic_reindexing_tasks, :elastic_task, :text
    add_column :elastic_reindexing_tasks, :documents_count_target, :integer

    add_text_limit :elastic_reindexing_tasks, :index_name_from, 255
    add_text_limit :elastic_reindexing_tasks, :index_name_to, 255
    add_text_limit :elastic_reindexing_tasks, :elastic_task, 255
  end
end
