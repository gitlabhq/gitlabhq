# frozen_string_literal: true

class CreateVirtualRegistriesContainerRegistryUpstreams < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_container_registry_upstreams

  def up
    with_lock_retries do
      create_table TABLE_NAME, if_not_exists: true do |t|
        t.references :group,
          null: false,
          index: { name: 'idx_vreg_container_reg_upst_on_group' },
          foreign_key: { to_table: :namespaces, on_delete: :cascade }
        t.references :registry,
          null: false,
          index: false,
          foreign_key: { to_table: :virtual_registries_container_registries, on_delete: :cascade }
        t.references :upstream,
          null: false,
          index: false,
          foreign_key: { to_table: :virtual_registries_container_upstreams, on_delete: :cascade }

        t.timestamps_with_timezone null: false
        t.integer :position, limit: 2, null: false, default: 1
      end
    end

    add_index TABLE_NAME, [:upstream_id, :registry_id],
      unique: true,
      name: 'virtual_reg_cont_reg_upstreams_on_upstream_and_registry_ids'

    constraint = check_constraint_name(TABLE_NAME, 'position', 'range')
    add_check_constraint(TABLE_NAME, '1 <= position AND position <= 5', constraint)
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
