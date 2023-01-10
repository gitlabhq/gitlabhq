# frozen_string_literal: true

class AddReportedFromToAbuseReports < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      unless column_exists?(:abuse_reports, :reported_from_url)
        add_column :abuse_reports, :reported_from_url, :text, null: false, default: ''
      end
    end

    add_text_limit :abuse_reports, :reported_from_url, 512
  end

  def down
    with_lock_retries do
      remove_column :abuse_reports, :reported_from_url if column_exists?(:abuse_reports, :reported_from_url)
    end
  end
end
