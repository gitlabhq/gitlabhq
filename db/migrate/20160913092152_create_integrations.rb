class CreateIntegrations < ActiveRecord::Migration
  def change
    create_table :integrations do |t|
      t.references :project, index: true, foreign_key: true
      t.string :name
      t.string :external_token

      t.timestamps null: false
    end

    add_index :integrations, :external_token, unique: true
  end
end
