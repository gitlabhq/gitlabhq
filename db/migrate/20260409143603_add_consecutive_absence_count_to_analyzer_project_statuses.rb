# frozen_string_literal: true

class AddConsecutiveAbsenceCountToAnalyzerProjectStatuses < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :analyzer_project_statuses, :consecutive_absence_count, :integer, default: 0, null: false
  end
end
