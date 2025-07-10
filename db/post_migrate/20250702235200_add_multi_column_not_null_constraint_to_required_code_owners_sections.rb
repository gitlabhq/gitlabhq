# frozen_string_literal: true

class AddMultiColumnNotNullConstraintToRequiredCodeOwnersSections < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:required_code_owners_sections, :protected_branch_project_id,
      :protected_branch_namespace_id)
  end

  def down
    remove_multi_column_not_null_constraint(:required_code_owners_sections, :protected_branch_project_id,
      :protected_branch_namespace_id)
  end
end
