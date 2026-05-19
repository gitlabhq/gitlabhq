# frozen_string_literal: true

class QueueRemoveDuplicateDefaultTrackedContexts < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "RemoveDuplicateDefaultTrackedContexts"

  def up
    # no-op because the BBM did not have the required indices
    # requeued in db/post_migrate/20260417104556_requeue_remove_duplicate_default_tracked_contexts.rb
  end

  def down
    # no-op
  end
end
