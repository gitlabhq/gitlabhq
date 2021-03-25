# frozen_string_literal: true

class CreateElasticIndexSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table_with_constraints :elastic_index_settings do |t|
      t.timestamps_with_timezone null: false
      t.integer :number_of_replicas, null: false, default: 1, limit: 2
      t.integer :number_of_shards, null: false, default: 5, limit: 2
      t.text :alias_name, null: false

      t.text_limit :alias_name, 255
      t.index :alias_name, unique: true
    end
  end

  def down
    drop_table :elastic_index_settings
  end
end
