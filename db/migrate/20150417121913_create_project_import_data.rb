class CreateProjectImportData < ActiveRecord::Migration
  def change
    create_table :project_import_data do |t|
      t.references :project
      t.text :data
    end
  end
end
