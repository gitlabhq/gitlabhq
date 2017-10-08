# rubocop:disable all
class ProjectsAddPushesSinceGc < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :pushes_since_gc, :integer, default: 0
  end
end
