# frozen_string_literal: true

class ValidateNotNullShardingKeyOnAbuseReports < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    validate_not_null_constraint :abuse_reports, :organization_id
  end

  def down; end
end
