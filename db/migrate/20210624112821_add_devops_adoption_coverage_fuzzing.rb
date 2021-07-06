# frozen_string_literal: true

class AddDevopsAdoptionCoverageFuzzing < ActiveRecord::Migration[6.1]
  def change
    add_column :analytics_devops_adoption_snapshots, :coverage_fuzzing_enabled_count, :integer
  end
end
