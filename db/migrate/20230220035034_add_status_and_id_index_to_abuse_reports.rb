# frozen_string_literal: true

class AddStatusAndIdIndexToAbuseReports < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_abuse_reports_on_status_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :abuse_reports, [:status, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :abuse_reports, INDEX_NAME
  end
end
