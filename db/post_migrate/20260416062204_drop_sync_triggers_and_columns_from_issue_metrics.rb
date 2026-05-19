# frozen_string_literal: true

class DropSyncTriggersAndColumnsFromIssueMetrics < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  TABLE = :issue_metrics
  COLUMNS = %i[id issue_id].freeze

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    # no op
  end
end
