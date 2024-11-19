# frozen_string_literal: true

class AddDependencyListExportsProjectIdGroupIdOrganizationIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  TABLE_NAME = :dependency_list_exports

  def up
    add_multi_column_not_null_constraint(TABLE_NAME,
      :organization_id,
      :group_id,
      :project_id,
      operator: '>',
      limit: 0
    )
  end

  def down
    remove_multi_column_not_null_constraint(TABLE_NAME, :organization_id, :group_id, :project_id)
  end
end
