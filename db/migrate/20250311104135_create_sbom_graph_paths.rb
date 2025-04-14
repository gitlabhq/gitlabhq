# frozen_string_literal: true

class CreateSbomGraphPaths < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    create_table :sbom_graph_paths do |t|
      t.bigint :ancestor_id, null: false
      t.bigint :descendant_id, null: false
      t.bigint :project_id, null: false
      t.integer :path_length, null: false

      t.index :ancestor_id
      t.index :descendant_id
      t.index [:project_id, :descendant_id]
      t.timestamps_with_timezone null: false
    end
  end
end
