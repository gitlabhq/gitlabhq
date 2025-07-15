# frozen_string_literal: true

class QueueBackfillBulkImportTrackersProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillBulkImportTrackersProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    # no-op because the original migration ran but was not successful https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188587#note_2457847947
  end

  def down
    # no-op because the original migration ran but was not successful https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188587#note_2457847947
  end
end
