# rubocop:disable all
class AllowMergesForForks < ActiveRecord::Migration
  def self.up
    add_column :merge_requests, :target_project_id, :integer, :null => true
    execute "UPDATE #{table_name} SET target_project_id = project_id"
    change_column :merge_requests, :target_project_id, :integer, :null => false
    rename_column :merge_requests, :project_id, :source_project_id
  end

  def self.down
    remove_column :merge_requests, :target_project_id
    rename_column :merge_requests, :source_project_id,:project_id
  end

  private

  def table_name
    MergeRequest.table_name
  end
end
