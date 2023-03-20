# frozen_string_literal: true

class AddStatusAndResolvedAtToAbuseReports < Gitlab::Database::Migration[2.1]
  def change
    add_column :abuse_reports, :status, :integer, limit: 2, default: 1, null: false
    add_timestamps_with_timezone(:abuse_reports, columns: [:resolved_at], null: true)
  end
end
