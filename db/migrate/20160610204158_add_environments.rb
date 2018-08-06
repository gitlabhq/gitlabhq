# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
class AddEnvironments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    create_table :environments, force: true do |t|
      t.integer  :project_id, null: false
      t.string   :name,       null: false
      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index :environments, [:project_id, :name]
  end
end
