# frozen_string_literal: true

class ScopeGovernPoliciesNameUniquenessToNamespace < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  OLD_INDEX = 'unique_govern_policies_organization_id_and_name'
  NEW_INDEX = 'unique_govern_policies_org_namespace_and_name'

  def up
    # nulls_not_distinct ensures organization-wide policies (namespace_id IS NULL)
    # are still unique within the organization, since PostgreSQL normally treats
    # NULL values as distinct in unique indexes.
    add_concurrent_index :govern_policies, [:organization_id, :namespace_id, :name],
      unique: true, nulls_not_distinct: true, name: NEW_INDEX

    remove_concurrent_index_by_name :govern_policies, OLD_INDEX
  end

  def down
    add_concurrent_index :govern_policies, [:organization_id, :name],
      unique: true, name: OLD_INDEX

    remove_concurrent_index_by_name :govern_policies, NEW_INDEX
  end
end
