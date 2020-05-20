# frozen_string_literal: true

class AddMergeRequestsRequireCodeOwnerApprovalToProtectedBranches < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default( # rubocop:disable Migration/AddColumnWithDefault
      :protected_branches,
      :code_owner_approval_required,
      :boolean,
      default: false
    )

    add_concurrent_index(
      :protected_branches,
      [:project_id, :code_owner_approval_required],
      name: "code_owner_approval_required",
      where: "code_owner_approval_required = #{Gitlab::Database.true_value}")
  end

  def down
    remove_concurrent_index(:protected_branches, name: "code_owner_approval_required")

    remove_column(:protected_branches, :code_owner_approval_required)
  end
end
