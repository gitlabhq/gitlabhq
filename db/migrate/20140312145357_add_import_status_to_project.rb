# rubocop:disable all
class AddImportStatusToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :import_status, :string
  end
end
