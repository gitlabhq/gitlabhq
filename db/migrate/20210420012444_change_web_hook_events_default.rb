# frozen_string_literal: true

class ChangeWebHookEventsDefault < ActiveRecord::Migration[6.0]
  def up
    change_column_default :web_hooks, :push_events, true
    change_column_default :web_hooks, :issues_events, false
    change_column_default :web_hooks, :merge_requests_events, false
    change_column_default :web_hooks, :tag_push_events, false
  end

  # This is a NOP because this migration is supposed to restore the
  # intended schema, not revert it.
  def down
  end
end
