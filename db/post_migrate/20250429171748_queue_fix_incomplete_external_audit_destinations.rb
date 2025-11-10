# frozen_string_literal: true

class QueueFixIncompleteExternalAuditDestinations < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # No-op: Superseded by QueueFixIncompleteGroupExternalAuditDestinationsV2
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210375
  end

  def down
    # No-op
  end
end
