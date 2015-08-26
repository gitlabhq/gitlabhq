class AddSkipRefsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :skip_refs, :string
  end
end
