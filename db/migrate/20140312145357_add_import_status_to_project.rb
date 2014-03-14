class AddImportStatusToProject < ActiveRecord::Migration
  def change
    add_column :projects, :import_status, :string
  end
end
