# frozen_string_literal: true

class AddCheckConstraintToWorkItemCurrentStatuses < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  def up
    # Ensure that either system_defined_status_id or custom_status_id is not null
    # but allow both ids to be set.
    add_multi_column_not_null_constraint(
      :work_item_current_statuses, :system_defined_status_id, :custom_status_id, limit: 0, operator: '>'
    )
  end

  def down
    remove_multi_column_not_null_constraint(:work_item_current_statuses, :system_defined_status_id, :custom_status_id)
  end
end
