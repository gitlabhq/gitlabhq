class CreateFeatureTables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def self.up
    create_table :features do |t|
      t.string :key, null: false
      t.timestamps null: false
    end
    add_index :features, :key, unique: true

    create_table :feature_gates do |t|
      t.string :feature_key, null: false
      t.string :key, null: false
      t.string :value
      t.timestamps null: false
    end
    add_index :feature_gates, [:feature_key, :key, :value], unique: true
  end

  def self.down
    drop_table :feature_gates
    drop_table :features
  end
end
