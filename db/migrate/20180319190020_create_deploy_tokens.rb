class CreateDeployTokens < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :deploy_tokens do |t|
      t.boolean :revoked, default: false
      t.boolean :read_repository, null: false, default: false
      t.boolean :read_registry, null: false, default: false

      t.datetime :expires_at
      t.timestamps null: false

      t.string :name, null: false
      t.string :token, index: { unique: true }, null: false
    end
  end
end
