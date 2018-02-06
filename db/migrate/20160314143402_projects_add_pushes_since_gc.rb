# rubocop:disable all
class ProjectsAddPushesSinceGc < ActiveRecord::Migration
  def change
    add_column :projects, :pushes_since_gc, :integer, default: 0
  end
end
