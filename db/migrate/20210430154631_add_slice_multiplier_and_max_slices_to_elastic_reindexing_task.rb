# frozen_string_literal: true
class AddSliceMultiplierAndMaxSlicesToElasticReindexingTask < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DEFAULT_MAX_TOTAL_SLICES_RUNNING = 60
  DEFAULT_SLICE_MULTIPLIER = 2

  def change
    add_column :elastic_reindexing_tasks, :max_slices_running, :integer,
               limit: 2,
               default: DEFAULT_MAX_TOTAL_SLICES_RUNNING,
               null: false
    add_column :elastic_reindexing_tasks, :slice_multiplier, :integer,
               limit: 2,
               default: DEFAULT_SLICE_MULTIPLIER,
               null: false
  end
end
