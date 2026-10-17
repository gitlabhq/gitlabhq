# frozen_string_literal: true

class CreateDuoCodeReviewFindings < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  def up
    # no-op
    #
    # Disabled as part of reverting https://gitlab.com/gitlab-org/gitlab/-/merge_requests/262175.
    # See https://docs.gitlab.com/development/database/deleting_migrations/#how-to-disable-a-data-migration
  end

  def down
    # no-op
  end
end
