# rubocop:disable all
class RemoveImportDataFromProject < ActiveRecord::Migration[4.2]
  def up
    remove_column :projects, :import_data
  end

  def down
    add_column :projects, :import_data, :text
  end
end
