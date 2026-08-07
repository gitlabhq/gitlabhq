# frozen_string_literal: true

class MakeNamespaceIdNullableOnGovernPolicies < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  OWNED_BY_NAMESPACE_INDEX = 'unique_govern_policies_org_namespace_and_name'
  OWNED_BY_ORGANIZATION_INDEX = 'unique_govern_policies_org_and_name_without_namespace'
  EVALUATION_INDEX = 'index_govern_policies_on_org_trigger_lifecycle_and_id'
  SUPERSEDED_UNIQUE_INDEX = 'unique_govern_policies_organization_id_namespace_id_and_name'

  def up
    add_concurrent_index :govern_policies, [:organization_id, :namespace_id, :name],
      unique: true, where: 'namespace_id IS NOT NULL', name: OWNED_BY_NAMESPACE_INDEX
    add_concurrent_index :govern_policies, [:organization_id, :name],
      unique: true, where: 'namespace_id IS NULL', name: OWNED_BY_ORGANIZATION_INDEX
    add_concurrent_index :govern_policies, [:organization_id, :trigger_type, :lifecycle_state, :id],
      name: EVALUATION_INDEX

    remove_concurrent_index_by_name :govern_policies, SUPERSEDED_UNIQUE_INDEX

    change_column_null :govern_policies, :namespace_id, true
  end

  def down
    change_column_null :govern_policies, :namespace_id, false

    add_concurrent_index :govern_policies, [:organization_id, :namespace_id, :name],
      unique: true, name: SUPERSEDED_UNIQUE_INDEX

    remove_concurrent_index_by_name :govern_policies, EVALUATION_INDEX
    remove_concurrent_index_by_name :govern_policies, OWNED_BY_ORGANIZATION_INDEX
    remove_concurrent_index_by_name :govern_policies, OWNED_BY_NAMESPACE_INDEX
  end
end
