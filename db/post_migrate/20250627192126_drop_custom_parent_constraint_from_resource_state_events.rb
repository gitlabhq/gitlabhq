# frozen_string_literal: true

class DropCustomParentConstraintFromResourceStateEvents < Gitlab::Database::Migration[2.3]
  TABLE = :resource_state_events
  CONSTRAINT_NAME = 'state_events_must_belong_to_issue_or_merge_request_or_epic'

  disable_ddl_transaction!
  milestone '18.2'

  def up
    remove_check_constraint TABLE, CONSTRAINT_NAME
  end

  def down
    add_check_constraint(
      TABLE,
      "(issue_id != NULL AND merge_request_id IS NULL AND epic_id IS NULL) OR " \
        "(issue_id IS NULL AND merge_request_id != NULL AND epic_id IS NULL) OR " \
        "(issue_id IS NULL AND merge_request_id IS NULL AND epic_id != NULL)",
      CONSTRAINT_NAME
    )
  end
end
