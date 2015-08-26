class AddTmpFileToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :tmp_file, :string
  end
end
