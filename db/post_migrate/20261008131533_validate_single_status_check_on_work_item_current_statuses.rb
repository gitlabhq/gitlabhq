# frozen_string_literal: true

class ValidateSingleStatusCheckOnWorkItemCurrentStatuses < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  TABLE_NAME = :work_item_current_statuses
  COLUMNS = %i[custom_status_id system_defined_status_id].freeze
  CONSTRAINT_NAME = 'check_wi_current_statuses_single_status'

  def up
    validate_multi_column_not_null_constraint(TABLE_NAME, *COLUMNS, constraint_name: CONSTRAINT_NAME)

    # The original "at least one" constraint is implied by "exactly one".
    remove_multi_column_not_null_constraint(TABLE_NAME, *COLUMNS)
  end

  def down
    add_multi_column_not_null_constraint(TABLE_NAME, *COLUMNS, limit: 0, operator: '>')
  end
end
