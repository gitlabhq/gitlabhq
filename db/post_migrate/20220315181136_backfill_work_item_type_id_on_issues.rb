# frozen_string_literal: true

class BackfillWorkItemTypeIdOnIssues < Gitlab::Database::Migration[1.0]
  def up
    # no-op
    # This migration will be rescheduled as described in
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85212
  end

  def down
    # no-op
  end
end
