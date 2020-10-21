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

        attr_reader :indexes

        def initialize(indexes)
          @indexes = indexes
        end

        def perform
          indexes.each do |index|
            # This obtains a global lease such that there's
            # only one live reindexing process at a time.
            try_obtain_lease do
              ReindexAction.keep_track_of(index) do
                ConcurrentReindex.new(index).perform
              end
            end
          end
        end

        private

        def lease_timeout
          TIMEOUT_PER_ACTION
        end
      end
    end
  end
end
