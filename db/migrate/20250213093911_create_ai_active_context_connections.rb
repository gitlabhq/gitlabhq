# frozen_string_literal: true

class CreateAiActiveContextConnections < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    create_table :ai_active_context_connections do |t|
      # Timestamps (8 bytes each)
      t.timestamps_with_timezone

      # Boolean (1 byte)
      t.boolean :active, null: false, default: false

      # Variable size columns (at the end)
      t.text :name, null: false, limit: 255, index: { unique: true }
      t.text :prefix, limit: 255
      t.text :adapter_class, null: false, limit: 255
      t.jsonb :options, null: false

      t.index :active, unique: true, where: 'active = true', name: 'index_active_context_connections_single_active'
    end
  end
end
