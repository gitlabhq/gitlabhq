# frozen_string_literal: true

class ReschedulePendingJobsForRecalculateVulnerabilitiesOccurrencesUuid < Gitlab::Database::Migration[1.0]
  def up
    # no-op
    # no replacement because we will reschedule this for the whole table
  end

  def down
    # no-op
  end
end
