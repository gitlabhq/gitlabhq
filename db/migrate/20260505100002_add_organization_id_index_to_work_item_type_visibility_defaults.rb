# frozen_string_literal: true

class AddOrganizationIdIndexToWorkItemTypeVisibilityDefaults < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  ORG_INDEX_NAME = 'uniq_wi_type_visibility_defaults_on_org_and_type'
  OLD_NS_INDEX_NAME = 'uniq_wi_type_visibility_defaults_on_namespace_and_type'
  NEW_NS_INDEX_NAME = 'uniq_wi_type_visibility_defaults_on_namespace_and_type'

  def up
    add_concurrent_index(
      :work_item_type_visibility_defaults,
      [:organization_id, :work_item_type_id],
      unique: true,
      where: 'organization_id IS NOT NULL',
      name: ORG_INDEX_NAME
    )

    remove_concurrent_index_by_name :work_item_type_visibility_defaults, OLD_NS_INDEX_NAME

    add_concurrent_index(
      :work_item_type_visibility_defaults,
      [:namespace_id, :work_item_type_id],
      unique: true,
      where: 'namespace_id IS NOT NULL',
      name: NEW_NS_INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :work_item_type_visibility_defaults, ORG_INDEX_NAME

    remove_concurrent_index_by_name :work_item_type_visibility_defaults, NEW_NS_INDEX_NAME

    add_concurrent_index(
      :work_item_type_visibility_defaults,
      [:namespace_id, :work_item_type_id],
      unique: true,
      name: OLD_NS_INDEX_NAME
    )
  end
end
