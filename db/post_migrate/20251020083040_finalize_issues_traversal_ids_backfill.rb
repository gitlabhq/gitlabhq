# frozen_string_literal: true

class FinalizeIssuesTraversalIdsBackfill < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  disable_ddl_transaction!

  def up
    # no-op: This migration has been requeued by RequeueBackfillNamespaceTraversalIdsOnIssues
  end

  def down; end
end
