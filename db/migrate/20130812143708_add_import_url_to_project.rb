class AddImportUrlToProject < ActiveRecord::Migration
  def change
    add_column :projects, :import_url, :string
  end
end
