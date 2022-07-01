# frozen_string_literal: true

class RenameBuildsSidekiqQueuesToNamespaces < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BUILD_OLD_QUEUE = 'pipeline_processing:build_finished'
  BUILD_NEW_QUEUE = 'pipeline_processing:ci_build_finished'

  TRACE_OLD_QUEUE = 'pipeline_background:archive_trace'
  TRACE_NEW_QUEUE = 'pipeline_background:ci_archive_trace'

  def up
    sidekiq_queue_migrate BUILD_OLD_QUEUE, to: BUILD_NEW_QUEUE
    sidekiq_queue_migrate TRACE_OLD_QUEUE, to: TRACE_NEW_QUEUE
  end

  def down
    sidekiq_queue_migrate BUILD_NEW_QUEUE, to: BUILD_OLD_QUEUE
    sidekiq_queue_migrate TRACE_NEW_QUEUE, to: TRACE_OLD_QUEUE
  end
end
