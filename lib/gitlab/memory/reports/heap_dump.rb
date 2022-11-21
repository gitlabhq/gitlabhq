# frozen_string_literal: true

module Gitlab
  module Memory
    module Reports
      class HeapDump
        class << self
          def enqueue!
            log_event('enqueue')
            @write_heap_dump = true
          end

          # This is a no-op currently and will be implemented at a later time in
          # https://gitlab.com/gitlab-org/gitlab/-/issues/370077
          def write_conditionally
            return false unless enqueued?

            log_event('write')

            true
          end

          private

          def enqueued?
            !!@write_heap_dump
          end

          def log_event(message)
            Gitlab::AppLogger.info(
              message: message,
              pid: $$,
              worker_id: worker_id,
              perf_report: 'heap_dump'
            )
          end

          def worker_id
            ::Prometheus::PidProvider.worker_id
          end
        end
      end
    end
  end
end
