class AddCiConfigFileToProject < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :projects, :ci_config_file, :string
  end

  def down
    remove_column :projects, :ci_config_file
  end
end
