# frozen_string_literal: true

class CleanupProjectPipelineStatusKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  # TODO: to remove after feature-flag in duplicate-jobs client middleware is removed
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION_WORKER_CLASS = 'BackfillProjectPipelineStatusTtl'

  def up
    queue_redis_migration_job(MIGRATION_WORKER_CLASS)
  end

  def down
    # no-op
  end
end
