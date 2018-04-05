class CreateDeployTokens < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :deploy_tokens do |t|
      t.string :name, null: false
      t.string :token, index: { unique: true }, null: false
      t.boolean :read_repository, default: false
      t.boolean :read_registry, default: false
      t.boolean :revoked, default: false
      t.datetime :expires_at

      t.timestamps null: false
    end
  end
end
