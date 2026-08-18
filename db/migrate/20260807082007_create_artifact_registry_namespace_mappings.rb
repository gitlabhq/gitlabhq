# frozen_string_literal: true

class CreateArtifactRegistryNamespaceMappings < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  ORGANIZATION_INDEX_NAME = 'index_artifact_registry_namespace_mappings_on_organization_id'

  def change
    create_table :artifact_registry_namespace_mappings do |t|
      t.references :organization,
        foreign_key: { on_delete: :cascade },
        index: { unique: true, name: ORGANIZATION_INDEX_NAME },
        null: false
      t.uuid :ar_namespace_id, null: false
      t.timestamps_with_timezone null: false
    end
  end
end
