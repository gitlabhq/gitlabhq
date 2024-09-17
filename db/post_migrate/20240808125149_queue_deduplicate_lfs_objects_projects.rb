# frozen_string_literal: true

class QueueDeduplicateLfsObjectsProjects < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  MIGRATION = 'DeduplicateLfsObjectsProjects'
  TABLE_NAME = :lfs_objects_projects
  DELAY_INTERVAL = 100
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 2_500

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  # To be re-enqueued by db/post_migrate/20240827204855_reenqueue_deduplicate_lfs_objects_projects.rb
  def up
    # no-op
  end

  def down
    # no-op
  end
end
