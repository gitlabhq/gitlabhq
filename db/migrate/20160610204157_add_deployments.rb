# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
class AddDeployments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    create_table :deployments, force: true do |t|
      t.integer  :iid,            null: false
      t.integer  :project_id,     null: false
      t.integer  :environment_id, null: false
      t.string   :ref,            null: false
      t.boolean  :tag,            null: false
      t.string   :sha,            null: false
      t.integer  :user_id
      t.integer  :deployable_id
      t.string   :deployable_type
      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index :deployments, :project_id
    add_index :deployments, [:project_id, :iid], unique: true
    add_index :deployments, [:project_id, :environment_id]
    add_index :deployments, [:project_id, :environment_id, :iid]
  end
end
