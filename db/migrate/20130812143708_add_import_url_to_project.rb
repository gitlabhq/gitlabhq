# rubocop:disable all
class AddImportUrlToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :import_url, :string
  end
end
