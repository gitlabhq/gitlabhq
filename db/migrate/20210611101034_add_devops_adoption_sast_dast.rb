# frozen_string_literal: true

class AddDevopsAdoptionSastDast < ActiveRecord::Migration[6.1]
  def change
    add_column :analytics_devops_adoption_snapshots, :sast_enabled_count, :integer
    add_column :analytics_devops_adoption_snapshots, :dast_enabled_count, :integer
  end
end
