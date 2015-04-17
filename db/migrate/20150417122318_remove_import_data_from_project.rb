class RemoveImportDataFromProject < ActiveRecord::Migration
  def change
    remove_column :projects, :import_data
  end
end
