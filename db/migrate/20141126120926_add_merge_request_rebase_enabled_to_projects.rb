# rubocop:disable all
class AddMergeRequestRebaseEnabledToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :merge_requests_rebase_enabled, :boolean, default: false
  end
end
