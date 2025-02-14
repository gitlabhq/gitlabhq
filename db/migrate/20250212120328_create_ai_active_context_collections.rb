# frozen_string_literal: true

class CreateAiActiveContextCollections < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    create_table :ai_active_context_collections do |t|
      t.text :name, null: false, limit: 255
      t.jsonb :metadata, null: false, default: {}
      t.integer :number_of_partitions, default: 1, null: false
      t.timestamps_with_timezone null: false
    end
  end

  def down
    drop_table :ai_active_context_collections
  end
end
