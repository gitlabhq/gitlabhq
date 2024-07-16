# frozen_string_literal: true

class DeleteAbuseReportRecordsFromNotes < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.2'

  def up
    notes = define_batchable_model('notes')
    abuse_reports = define_batchable_model('abuse_reports')

    abuse_reports.each_batch do |batch|
      notes.where(noteable_type: 'AbuseReport', noteable_id: batch.pluck(:id)).delete_all
    end
  end

  def down
    # noop
  end
end
