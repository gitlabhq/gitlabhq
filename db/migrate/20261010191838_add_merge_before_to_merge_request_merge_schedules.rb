# frozen_string_literal: true

class AddMergeBeforeToMergeRequestMergeSchedules < Gitlab::Database::Migration[2.3]
  milestone '19.6'

  def change
    add_column :merge_request_merge_schedules, :merge_before, :datetime_with_timezone
  end
end
