class AddImportErrorToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :import_error, :text
  end
end
