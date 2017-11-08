# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateProjectSettings < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :project_settings do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }
    end
  end
end
