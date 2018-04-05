class CreateProjectDeployTokens < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :project_deploy_tokens do |t|
      t.integer :project_id, null: false
      t.integer :deploy_token_id, null: false
      t.timestamps null: false

      t.foreign_key :deploy_tokens, column: :deploy_token_id, on_delete: :cascade
      t.foreign_key :projects, column: :project_id, on_delete: :cascade

      t.index [:project_id, :deploy_token_id], unique: true
    end
  end
end
