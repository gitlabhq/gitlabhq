# frozen_string_literal: true

class QueueBackfillNamespacesRedirectRoutesNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillNamespacesRedirectRoutesNamespaceId"

  def change
    # no-op because there was a performance concern in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186774
  end
end
