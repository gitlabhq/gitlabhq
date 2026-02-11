# frozen_string_literal: true

class AddLocalUpstreamIdOnVregPackagesMavenRegistryUpstreams < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.9'

  TABLE_NAME = :virtual_registries_packages_maven_registry_upstreams
  INDEX_NAME = :idx_mvn_reg_upstreams_on_local_upstream_and_registry_ids

  def up
    with_lock_retries do
      add_column TABLE_NAME, :local_upstream_id, :bigint
      add_foreign_key TABLE_NAME, :virtual_registries_packages_maven_local_upstreams,
        column: :local_upstream_id, on_delete: :cascade
    end

    add_concurrent_index TABLE_NAME, [:local_upstream_id, :registry_id],
      unique: true,
      name: INDEX_NAME,
      where: 'local_upstream_id IS NOT NULL'

    constraint = check_constraint_name(TABLE_NAME, 'upstream', 'mutually_exclusive')
    add_check_constraint TABLE_NAME,
      'num_nonnulls(upstream_id, local_upstream_id) = 1', constraint
  end

  def down
    remove_check_constraint TABLE_NAME, check_constraint_name(TABLE_NAME, 'upstream', 'mutually_exclusive')
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)

    with_lock_retries do
      remove_foreign_key TABLE_NAME, column: :local_upstream_id
      remove_column TABLE_NAME, :local_upstream_id
    end
  end
end
