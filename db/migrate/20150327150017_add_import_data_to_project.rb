class AddImportDataToProject < ActiveRecord::Migration
  def change
    add_column :projects, :import_data, :text
  end
end
