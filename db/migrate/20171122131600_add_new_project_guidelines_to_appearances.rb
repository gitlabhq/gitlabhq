class AddNewProjectGuidelinesToAppearances < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_table :appearances do |t|
      t.text :new_project_guidelines
      t.text :new_project_guidelines_html
    end
  end
end
