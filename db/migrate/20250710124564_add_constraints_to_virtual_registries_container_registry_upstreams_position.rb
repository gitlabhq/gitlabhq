# frozen_string_literal: true

class AddConstraintsToVirtualRegistriesContainerRegistryUpstreamsPosition < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_container_registry_upstreams
  GROUP_INDEX_NAME = 'idx_vreg_container_reg_upst_on_group'
  REGISTRY_POSITION_CONSTRAINT_NAME = 'constraint_vreg_container_reg_upst_on_unique_reg_pos'

  def up
    execute <<-SQL
      ALTER TABLE #{TABLE_NAME}
      ADD CONSTRAINT #{REGISTRY_POSITION_CONSTRAINT_NAME}
      UNIQUE (registry_id, position) DEFERRABLE INITIALLY DEFERRED;
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE #{TABLE_NAME}
      DROP CONSTRAINT IF EXISTS #{REGISTRY_POSITION_CONSTRAINT_NAME};
    SQL
  end
end
