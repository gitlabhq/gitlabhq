# frozen_string_literal: true

class CreateAiInstanceAccessibleEntityRules < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def change
    create_table :ai_instance_accessible_entity_rules do |t|
      t.references :through_namespace,
        null: false,
        index: false,
        foreign_key: { to_table: :namespaces, on_delete: :cascade }

      t.timestamps_with_timezone null: false

      t.text :accessible_entity, null: false, limit: 255

      t.index [:through_namespace_id, :accessible_entity],
        unique: true,
        name: 'index_ai_iaer_on_through_namespace_on_accessible_entity'
    end
  end
end
