# frozen_string_literal: true

class QueueBackfillBulkImportExportsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  # This BBM is no longer needed, see gitlab-org/gitlab#604997. It's removed by
  # migration 20260806130010. No-op so already-run instances don't re-queue it.
  def up; end

  def down; end
end
