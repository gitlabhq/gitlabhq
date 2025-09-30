# frozen_string_literal: true

class AddNotNullConstraintAbuseReporToReporterId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  def up
    add_not_null_constraint(:abuse_reports, :reporter_id)
  end

  def down
    remove_not_null_constraint(:abuse_reports, :reporter_id)
  end
end
