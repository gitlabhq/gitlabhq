# frozen_string_literal: true

class CreateAiNamespaceFeatureAccessRules < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def change
    create_table :ai_namespace_feature_access_rules do |t|
      t.timestamps_with_timezone null: false

      t.bigint :root_namespace_id, null: false, index: false
      t.references :through_namespace,
        null: false,
        index: false,
        foreign_key: { to_table: :namespaces, on_delete: :cascade }

      t.text :accessible_entity, null: false, limit: 255

      t.index [:through_namespace_id, :accessible_entity],
        unique: true,
        name: 'index_ai_nfar_on_through_namespace_on_accessible_entity'

      t.index [:root_namespace_id, :accessible_entity],
        unique: false,
        name: 'index_ai_nfar_on_root_namespace_on_accessible_entity'
    end
  end
end
