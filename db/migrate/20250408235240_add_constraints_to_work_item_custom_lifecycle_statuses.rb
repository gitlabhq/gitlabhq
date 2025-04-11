# frozen_string_literal: true

class AddConstraintsToWorkItemCustomLifecycleStatuses < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_check_constraint :work_item_custom_lifecycle_statuses, 'position >= 0', constraint_name
  end

  def down
    remove_check_constraint :work_item_custom_lifecycle_statuses, constraint_name
  end

  private

  def constraint_name
    check_constraint_name(:work_item_custom_lifecycle_statuses, :position, 'positive')
  end
end
