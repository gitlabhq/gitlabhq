# frozen_string_literal: true

class AddRequiredCodeOwnersSectionsProtectedBranchNamespaceIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    install_sharding_key_assignment_trigger(
      table: :required_code_owners_sections,
      sharding_key: :protected_branch_namespace_id,
      parent_table: :protected_branches,
      parent_sharding_key: :namespace_id,
      foreign_key: :protected_branch_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :required_code_owners_sections,
      sharding_key: :protected_branch_namespace_id,
      parent_table: :protected_branches,
      parent_sharding_key: :namespace_id,
      foreign_key: :protected_branch_id
    )
  end
end
