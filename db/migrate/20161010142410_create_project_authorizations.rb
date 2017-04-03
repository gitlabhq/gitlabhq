class CreateProjectAuthorizations < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :project_authorizations do |t|
      t.references :user, foreign_key: { on_delete: :cascade }
      t.references :project, foreign_key: { on_delete: :cascade }
      t.integer :access_level

      t.index [:user_id, :project_id, :access_level], unique: true, name: 'index_project_authorizations_on_user_id_project_id_access_level'
    end
  end
end
