# frozen_string_literal: true

class AddStatusCreatedAtAndUpdatedAtIndexesToAbuseReports < Gitlab::Database::Migration[2.1]
  STATUS_AND_CREATED_AT_INDEX = 'index_abuse_reports_on_status_and_created_at'
  STATUS_AND_UPDATED_AT_INDEX = 'index_abuse_reports_on_status_and_updated_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :abuse_reports, [:status, :created_at], name: STATUS_AND_CREATED_AT_INDEX
    add_concurrent_index :abuse_reports, [:status, :updated_at], name: STATUS_AND_UPDATED_AT_INDEX
  end

  def down
    remove_concurrent_index_by_name :abuse_reports, STATUS_AND_CREATED_AT_INDEX
    remove_concurrent_index_by_name :abuse_reports, STATUS_AND_UPDATED_AT_INDEX
  end
end
