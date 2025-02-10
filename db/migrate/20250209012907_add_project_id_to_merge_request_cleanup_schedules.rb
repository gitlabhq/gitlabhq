# frozen_string_literal: true

class AddProjectIdToMergeRequestCleanupSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :merge_request_cleanup_schedules, :project_id, :bigint
  end
end
