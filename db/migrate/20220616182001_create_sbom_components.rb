# frozen_string_literal: true

class CreateSbomComponents < Gitlab::Database::Migration[2.0]
  def change
    create_table :sbom_components do |t|
      t.timestamps_with_timezone
      t.integer :component_type, null: false, limit: 2
      t.text :name, null: false, limit: 255
    end
  end
end
