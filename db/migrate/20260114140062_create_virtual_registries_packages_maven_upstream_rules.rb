# frozen_string_literal: true

class CreateVirtualRegistriesPackagesMavenUpstreamRules < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  TABLE_NAME = :virtual_registries_packages_maven_upstream_rules

  def change
    create_table TABLE_NAME do |t|
      t.references :remote_upstream,
        null: false,
        foreign_key: { to_table: :virtual_registries_packages_maven_upstreams, on_delete: :cascade },
        index: false # Covered by a multi-column unique index below
      t.references :group,
        null: false,
        foreign_key: { to_table: :namespaces, on_delete: :cascade },
        index: { name: 'index_maven_upstream_rules_on_group_id' }

      t.timestamps_with_timezone null: false

      t.integer :pattern_type, limit: 2, null: false, default: 0
      t.integer :rule_type, limit: 2, null: false, default: 0
      t.integer :target_coordinate, limit: 2, null: false, default: 0

      t.text :pattern, null: false, limit: 255

      t.index %i[remote_upstream_id target_coordinate pattern pattern_type rule_type],
        unique: true,
        name: 'unique_idx_mvn_upstream_rules_on_remote_upstream_target_pattern'
    end
  end
end
