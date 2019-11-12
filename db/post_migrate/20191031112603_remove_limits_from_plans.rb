# frozen_string_literal: true

class RemoveLimitsFromPlans < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    remove_column :plans, :active_pipelines_limit
    remove_column :plans, :pipeline_size_limit
    remove_column :plans, :active_jobs_limit
  end

  def down
    add_column :plans, :active_pipelines_limit, :integer
    add_column :plans, :pipeline_size_limit, :integer
    add_column :plans, :active_jobs_limit, :integer
  end
end
