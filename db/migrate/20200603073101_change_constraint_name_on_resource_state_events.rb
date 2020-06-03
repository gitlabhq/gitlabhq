# frozen_string_literal: true

class ChangeConstraintNameOnResourceStateEvents < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  NEW_CONSTRAINT_NAME = 'state_events_must_belong_to_issue_or_merge_request_or_epic'
  OLD_CONSTRAINT_NAME = 'resource_state_events_must_belong_to_issue_or_merge_request_or_epic'

  def up
    execute "ALTER TABLE resource_state_events RENAME CONSTRAINT #{OLD_CONSTRAINT_NAME} TO #{NEW_CONSTRAINT_NAME};"
  end

  def down
    execute "ALTER TABLE resource_state_events RENAME CONSTRAINT #{NEW_CONSTRAINT_NAME} TO #{OLD_CONSTRAINT_NAME};"
  end
end
