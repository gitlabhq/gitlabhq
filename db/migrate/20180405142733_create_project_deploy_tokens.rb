class CreateProjectDeployTokens < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :project_deploy_tokens do |t|
      t.integer :project_id, null: false
      t.integer :deploy_token_id, null: false

      t.timestamps null: false
    end

    add_concurrent_index :project_deploy_tokens, [:project_id, :deploy_token_id]
  end

  def down
    drop_table :project_deploy_tokens

    remove_index :project_deploy_tokens, column: [:project_id, :deploy_token_id] if index_exists?(:project_deploy_tokens, [:project_id, :deploy_token_id])
  end
end
