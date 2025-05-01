# frozen_string_literal: true

class ReplaceUniqIdxOnVregPkgsMvnRegUpstreamsPosWithUniqDeferConstraint <
  Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  TABLE_NAME = :virtual_registries_packages_maven_registry_upstreams
  INDEX_NAME = :idx_vreg_pkgs_mvn_reg_upst_on_unique_regid_pos
  CONSTRAINT_NAME = :constraint_vreg_pkgs_mvn_reg_upst_on_unique_regid_pos

  def up
    execute <<-SQL
      ALTER TABLE #{TABLE_NAME}
      ADD CONSTRAINT #{CONSTRAINT_NAME} UNIQUE USING INDEX #{INDEX_NAME}
      DEFERRABLE INITIALLY DEFERRED;
    SQL
  end

  def down
    add_concurrent_index TABLE_NAME,
      %i[registry_id position],
      name: INDEX_NAME,
      unique: true

    execute <<-SQL
      ALTER TABLE #{TABLE_NAME}
      DROP CONSTRAINT IF EXISTS #{CONSTRAINT_NAME};
    SQL
  end
end
