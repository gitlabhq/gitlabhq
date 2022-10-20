# frozen_string_literal: true

class AddTargetsToElasticReindexingTasks < Gitlab::Database::Migration[2.0]
  def change
    add_column :elastic_reindexing_tasks, :targets, :text, array: true
  end
end
