# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      class Coordinator
        include ExclusiveLeaseGuard

        # Maximum lease time for the global Redis lease
        # This should be higher than the maximum time for any
        # long running step in the reindexing process (compare with
        # statement timeouts).
        TIMEOUT_PER_ACTION = 1.day

        attr_reader :index, :notifier

        def initialize(index, notifier = GrafanaNotifier.new)
          @index = index
          @notifier = notifier
        end

        def perform
          # This obtains a global lease such that there's
          # only one live reindexing process at a time.
          try_obtain_lease do
            action = ReindexAction.create_for(index)

            with_notifications(action) do
              perform_for(index, action)
            end
          end
        end

        private

        def with_notifications(action)
          notifier.notify_start(action)
          yield
        ensure
          notifier.notify_end(action)
        end

        def perform_for(index, action)
          ReindexConcurrently.new(index).perform
        rescue StandardError
          action.state = :failed

          raise
        ensure
          action.finish
        end

        def lease_timeout
          TIMEOUT_PER_ACTION
        end
      end
    end
  end
end
