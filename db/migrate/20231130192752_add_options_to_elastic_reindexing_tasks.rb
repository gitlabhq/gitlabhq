# frozen_string_literal: true

class AddOptionsToElasticReindexingTasks < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def change
    add_column :elastic_reindexing_tasks, :options, :jsonb, null: false, default: {}
  end
end
