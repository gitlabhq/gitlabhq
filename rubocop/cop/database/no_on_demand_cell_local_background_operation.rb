# frozen_string_literal: true

module RuboCop
  module Cop
    module Database
      # Prevents on-demand enqueuing of
      # `Gitlab::Database::BackgroundOperation::WorkerCellLocal`.
      #
      # Cell-local background operations are stored under the
      # `gitlab_shared_cell_local` schema and are not migrated when an
      # organization moves to a new cell. On-demand enqueues would therefore
      # be silently lost. Only recurring cron jobs may enqueue cell-local
      # workers, via `Database::BackgroundOperation::CronEnqueueWorker`.
      #
      # See doc/development/database/background_operations.md for the full
      # rationale.
      #
      # @example
      #   # bad
      #   Gitlab::Database::BackgroundOperation::WorkerCellLocal.enqueue(
      #     'MyOperationClass', 'target_table', 'id'
      #   )
      #
      #   # good (recurring cron)
      #   # Register the operation in config/schedule.yml under
      #   # Database::BackgroundOperation::CronEnqueueWorker.
      class NoOnDemandCellLocalBackgroundOperation < RuboCop::Cop::Base
        MSG = <<~MSG
          Do not enqueue Gitlab::Database::BackgroundOperation::WorkerCellLocal on-demand.

          Cell local background operations are not migrated when an organization moves to
          a new cell, causing enqueued work to be lost. Only recurring cron jobs may enqueue cell-local
          workers, via `Database::BackgroundOperation::CronEnqueueWorker`.

          See doc/development/database/background_operations.md.
        MSG

        ALLOWED_PATH = 'app/workers/database/background_operation/cron_enqueue_worker.rb'

        RESTRICT_ON_SEND = %i[enqueue].freeze

        # @!method cell_local_enqueue?(node)
        def_node_matcher :cell_local_enqueue?, <<~PATTERN
          (send
            (const
              (const
                (const
                  (const {nil? cbase} :Gitlab) :Database) :BackgroundOperation) :WorkerCellLocal)
            :enqueue ...)
        PATTERN

        def on_send(node)
          return unless cell_local_enqueue?(node)
          return if allowed_file?

          add_offense(node)
        end
        alias_method :on_csend, :on_send

        private

        def allowed_file?
          processed_source.file_path.end_with?(ALLOWED_PATH)
        end
      end
    end
  end
end
