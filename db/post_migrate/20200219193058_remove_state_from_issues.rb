# frozen_string_literal: true

class RemoveStateFromIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless issue_state_column_exists?

    # Ignored in 12.6 - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/19574
    with_lock_retries do
      remove_column :issues, :state, :string
    end
  end

  def down
    return if issue_state_column_exists?

    with_lock_retries do
      add_column :issues, :state, :string
    end
  end

  private

  def issue_state_column_exists?
    column_exists?(:issues, :state)
  end
end
