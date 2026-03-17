# frozen_string_literal: true

class QueueBackfillNamespaceStateNullsToDefault < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    # no-op Re-queued in db/post_migrate/20260305093121_requeue_backfill_namespace_state_nulls_to_default.rb
    # because some records were not migrated.
  end

  def down
    # no-op Re-queued in db/post_migrate/20260305093121_requeue_backfill_namespace_state_nulls_to_default.rb
  end
end
