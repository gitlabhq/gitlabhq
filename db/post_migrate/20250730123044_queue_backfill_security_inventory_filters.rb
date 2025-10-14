# frozen_string_literal: true

class QueueBackfillSecurityInventoryFilters < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  MIGRATION = "BackfillSecurityInventoryFilters"

  def up
    # no-op because there was a bug that caused the data to drift. This bug was fixed by
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208074
  end

  def down
    # no-op because there was a bug that caused the data to drift. This bug was fixed by
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208074
  end
end
