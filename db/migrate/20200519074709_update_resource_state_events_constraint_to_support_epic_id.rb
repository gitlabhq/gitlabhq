# frozen_string_literal: true

class UpdateResourceStateEventsConstraintToSupportEpicId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  OLD_CONSTRAINT = 'resource_state_events_must_belong_to_issue_or_merge_request'
  CONSTRAINT_NAME = 'resource_state_events_must_belong_to_issue_or_merge_request_or_'

  def up
    remove_check_constraint :resource_state_events, OLD_CONSTRAINT
    add_check_constraint :resource_state_events, "(issue_id != NULL AND merge_request_id IS NULL AND epic_id IS NULL) OR " \
      "(issue_id IS NULL AND merge_request_id != NULL AND epic_id IS NULL) OR" \
      "(issue_id IS NULL AND merge_request_id IS NULL AND epic_id != NULL)", CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :resource_state_events, CONSTRAINT_NAME
    add_check_constraint :resource_state_events, '(issue_id != NULL AND merge_request_id IS NULL) OR (merge_request_id != NULL AND issue_id IS NULL)', OLD_CONSTRAINT
  end
end
