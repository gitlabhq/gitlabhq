class AddImportDataToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :import_data, :text
  end
end
