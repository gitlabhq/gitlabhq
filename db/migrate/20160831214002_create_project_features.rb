# rubocop:disable Migration/Timestamps
class CreateProjectFeatures < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    create_table :project_features do |t|
      t.belongs_to :project, index: true
      t.integer  :merge_requests_access_level
      t.integer  :issues_access_level
      t.integer  :wiki_access_level
      t.integer  :snippets_access_level
      t.integer  :builds_access_level

      t.timestamps null: true
    end
  end
end
