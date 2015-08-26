class AddRefFunctionality < ActiveRecord::Migration
  def change
    rename_column :builds, :commit_ref, :ref  
    add_column :builds, :sha, :string
    add_column :projects, :default_ref, :string
  end

  def down
  end
end
