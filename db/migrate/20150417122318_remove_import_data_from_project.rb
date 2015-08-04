class RemoveImportDataFromProject < ActiveRecord::Migration
  def up
    remove_column :projects, :import_data
  end

  def down
    add_column :projects, :import_data, :text
  end
end
