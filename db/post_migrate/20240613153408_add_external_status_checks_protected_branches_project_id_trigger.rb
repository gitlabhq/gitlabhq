# frozen_string_literal: true

class AddExternalStatusChecksProtectedBranchesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    install_sharding_key_assignment_trigger(
      table: :external_status_checks_protected_branches,
      sharding_key: :project_id,
      parent_table: :external_status_checks,
      parent_sharding_key: :project_id,
      foreign_key: :external_status_check_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :external_status_checks_protected_branches,
      sharding_key: :project_id,
      parent_table: :external_status_checks,
      parent_sharding_key: :project_id,
      foreign_key: :external_status_check_id
    )
  end
end
