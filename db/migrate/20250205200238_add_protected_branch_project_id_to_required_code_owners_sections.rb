# frozen_string_literal: true

class AddProtectedBranchProjectIdToRequiredCodeOwnersSections < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :required_code_owners_sections, :protected_branch_project_id, :bigint
  end
end
