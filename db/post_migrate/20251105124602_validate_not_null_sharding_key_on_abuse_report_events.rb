# frozen_string_literal: true

class ValidateNotNullShardingKeyOnAbuseReportEvents < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    validate_not_null_constraint :abuse_report_events, :organization_id
  end

  def down; end
end
