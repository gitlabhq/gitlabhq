# frozen_string_literal: true

class AddConstraintsToVirtualRegistriesPackagesNpmRegistryUpstreamsPosition < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  TABLE_NAME = :virtual_registries_packages_npm_registry_upstreams
  REGISTRY_POSITION_CONSTRAINT_NAME = 'constraint_vreg_pkgs_npm_reg_upst_on_unique_reg_pos'

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
