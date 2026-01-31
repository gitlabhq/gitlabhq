# frozen_string_literal: true

class CreateAscpComponentDependencies < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  def up
    create_table :ascp_component_dependencies do |t|
      # 8-byte columns first (timestamps, bigints)
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.bigint :component_id, null: false
      t.bigint :dependency_id, null: false
    end

    # Indexes (no standalone project_id - composite index covers it)
    add_index :ascp_component_dependencies, [:project_id, :component_id, :dependency_id],
      unique: true, name: 'idx_ascp_component_deps_on_proj_comp_dep'
    add_index :ascp_component_dependencies, :component_id
    add_index :ascp_component_dependencies, :dependency_id

    add_concurrent_foreign_key :ascp_component_dependencies, :ascp_components,
      column: :component_id, on_delete: :cascade
    add_concurrent_foreign_key :ascp_component_dependencies, :ascp_components,
      column: :dependency_id, on_delete: :cascade
  end

  def down
    drop_table :ascp_component_dependencies
  end
end
