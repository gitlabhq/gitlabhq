# frozen_string_literal: true

class AddDocumentsCountTargetToElasticReindexingTasks < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :elastic_reindexing_tasks, :documents_count_target, :integer
  end
end
