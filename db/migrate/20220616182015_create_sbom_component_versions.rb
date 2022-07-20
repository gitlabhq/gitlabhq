# frozen_string_literal: true

class CreateSbomComponentVersions < Gitlab::Database::Migration[2.0]
  def change
    create_table :sbom_component_versions do |t|
      t.timestamps_with_timezone
      t.references :component,
        index: true,
        null: false,
        foreign_key: { to_table: :sbom_components, on_delete: :cascade }

      t.text :version, null: false, limit: 255
    end
  end
end
