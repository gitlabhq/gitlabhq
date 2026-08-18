# frozen_string_literal: true

class ReplaceGovernPoliciesPartialNameIndexes < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  ORGANIZATION_AND_NAME_INDEX = 'unique_govern_policies_organization_id_and_name'
  SUPERSEDED_WITH_NAMESPACE_INDEX = 'unique_govern_policies_org_namespace_and_name'
  SUPERSEDED_WITHOUT_NAMESPACE_INDEX = 'unique_govern_policies_org_and_name_without_namespace'

  def up
    add_concurrent_index :govern_policies, [:organization_id, :name],
      unique: true, name: ORGANIZATION_AND_NAME_INDEX

    remove_concurrent_index_by_name :govern_policies, SUPERSEDED_WITHOUT_NAMESPACE_INDEX
    remove_concurrent_index_by_name :govern_policies, SUPERSEDED_WITH_NAMESPACE_INDEX
  end

  def down
    add_concurrent_index :govern_policies, [:organization_id, :namespace_id, :name],
      unique: true, where: 'namespace_id IS NOT NULL', name: SUPERSEDED_WITH_NAMESPACE_INDEX
    add_concurrent_index :govern_policies, [:organization_id, :name],
      unique: true, where: 'namespace_id IS NULL', name: SUPERSEDED_WITHOUT_NAMESPACE_INDEX

    remove_concurrent_index_by_name :govern_policies, ORGANIZATION_AND_NAME_INDEX
  end
end
