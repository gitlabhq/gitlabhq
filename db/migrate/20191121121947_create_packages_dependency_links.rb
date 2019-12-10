# frozen_string_literal: true

class CreatePackagesDependencyLinks < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :packages_dependency_links do |t|
      t.references :package, index: false, null: false, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :bigint
      t.references :dependency, null: false, foreign_key: { to_table: :packages_dependencies, on_delete: :cascade }, type: :bigint
      t.integer :dependency_type, limit: 2, null: false
    end

    add_index :packages_dependency_links, [:package_id, :dependency_id, :dependency_type], unique: true, name: 'idx_pkgs_dep_links_on_pkg_id_dependency_id_dependency_type'
  end
end
