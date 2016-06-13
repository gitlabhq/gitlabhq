# rubocop:disable all
class AddImportErrorToProject < ActiveRecord::Migration
  def change
    add_column :projects, :import_error, :text
  end
end
