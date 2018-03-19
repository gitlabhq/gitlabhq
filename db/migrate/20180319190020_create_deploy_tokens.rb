class CreateDeployTokens < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :deploy_tokens do |t|
      t.references :project, index: true, foreign_key: true, null: false
      t.string :name, null: false
      t.string :token, index: { unique: true }, null: false
      t.string :scopes
      t.boolean :revoked, default: false
      t.datetime :expires_at

      t.timestamps null: false
    end
  end
end
