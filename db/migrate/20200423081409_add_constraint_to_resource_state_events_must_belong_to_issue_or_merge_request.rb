# frozen_string_literal: true

class AddConstraintToResourceStateEventsMustBelongToIssueOrMergeRequest < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'resource_state_events_must_belong_to_issue_or_merge_request'

  def up
    add_check_constraint :resource_state_events, '(issue_id != NULL AND merge_request_id IS NULL) OR (merge_request_id != NULL AND issue_id IS NULL)', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :resource_state_events, CONSTRAINT_NAME
  end
end
