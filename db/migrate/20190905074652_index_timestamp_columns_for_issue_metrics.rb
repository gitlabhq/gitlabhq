# frozen_string_literal: true

class IndexTimestampColumnsForIssueMetrics < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(*index_arguments)
  end

  def down
    remove_concurrent_index(*index_arguments)
  end

  private

  def index_arguments
    [
      :issue_metrics,
      [:issue_id, :first_mentioned_in_commit_at, :first_associated_with_milestone_at, :first_added_to_board_at],
      {
        name: 'index_issue_metrics_on_issue_id_and_timestamps'
      }
    ]
  end
end
