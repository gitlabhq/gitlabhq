class AddModularityFieldsToProject < ActiveRecord::Migration
  def change
    add_column :projects, :issues_enabled, :boolean, :null => false, :default => true
    add_column :projects, :wall_enabled, :boolean, :null => false, :default => true
    add_column :projects, :merge_requests_enabled, :boolean, :null => false, :default => true
  end
end
