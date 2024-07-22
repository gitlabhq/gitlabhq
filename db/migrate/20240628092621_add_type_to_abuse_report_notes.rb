# frozen_string_literal: true

class AddTypeToAbuseReportNotes < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  def up
    with_lock_retries do
      add_column :abuse_report_notes, :type, :text, if_not_exists: true
    end

    add_text_limit :abuse_report_notes, :type, 40
  end

  def down
    with_lock_retries do
      remove_column :abuse_report_notes, :type, if_exists: true
    end
  end
end
