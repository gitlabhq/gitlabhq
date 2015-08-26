class AddShaIndexToBuild < ActiveRecord::Migration
  def change
    add_index :builds, :sha
    add_index :builds, [:project_id, :sha]
  end
end
