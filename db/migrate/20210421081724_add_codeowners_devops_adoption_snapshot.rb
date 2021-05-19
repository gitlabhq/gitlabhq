# frozen_string_literal: true

class AddCodeownersDevopsAdoptionSnapshot < ActiveRecord::Migration[6.0]
  def change
    add_column :analytics_devops_adoption_snapshots, :total_projects_count, :integer
    add_column :analytics_devops_adoption_snapshots, :code_owners_used_count, :integer
  end
end
