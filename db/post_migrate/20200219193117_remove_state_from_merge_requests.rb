# frozen_string_literal: true

class RemoveStateFromMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless merge_requests_state_column_exists?

    # Ignored in 12.6 - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/19574
    with_lock_retries do
      remove_column :merge_requests, :state, :string
    end
  end

  def down
    return if merge_requests_state_column_exists?

    with_lock_retries do
      add_column :merge_requests, :state, :string
    end
  end

  private

  def merge_requests_state_column_exists?
    column_exists?(:merge_requests, :state)
  end
end
