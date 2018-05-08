# rubocop:disable all
class AddAccessToProjectGroupLink < ActiveRecord::Migration
  def change
    add_column :project_group_links, :group_access, :integer, null: false, default: ProjectGroupLink.default_access
  end
end
