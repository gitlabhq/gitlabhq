class CreateProjectFeatures < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :project_features do |t|
      t.belongs_to :project, index: true
      t.integer  :merge_requests_access_level
      t.integer  :issues_access_level
      t.integer  :wiki_access_level
      t.integer  :snippets_access_level
      t.integer  :builds_access_level

      t.timestamps
    end
  end
end
