# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncIndexes
      class IndexDestructor < AsyncIndexes::IndexBase
        private

        override :preconditions_met?
        def preconditions_met?
          index_exists?
        end

        override :action_type
        def action_type
          'removal'
        end

        override :around_execution
        def around_execution(&block)
          retries = Gitlab::Database::WithLockRetriesOutsideTransaction.new(
            connection: connection,
            timing_configuration: Gitlab::Database::Reindexing::REMOVE_INDEX_RETRY_CONFIG,
            klass: self.class,
            logger: Gitlab::AppLogger
          )

          retries.run(raise_on_exhaustion: false, &block)
        end
      end
    end
  end
end
