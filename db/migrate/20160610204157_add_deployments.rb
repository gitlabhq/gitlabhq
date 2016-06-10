# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDeployments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    create_table :deployments, force: true do |t|
      t.integer  :iid
      t.integer  :project_id
      t.integer  :environment_id
      t.string   :ref
      t.boolean  :tag
      t.string   :sha
      t.integer  :user_id
      t.integer  :deployable_id,   null: false
      t.string   :deployable_type, null: false
      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index :deployments, :project_id
    add_index :deployments, [:project_id, :iid]
    add_index :deployments, [:project_id, :environment_id]
    add_index :deployments, [:project_id, :environment_id, :iid]
  end
end
