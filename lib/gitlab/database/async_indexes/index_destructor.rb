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

        # Coverage can change between scheduling and removal; a raise here lands
        # in postgres_async_indexes.last_error and the entry is retried.
        override :execute_action
        def execute_action
          index = connection.indexes(async_index.table_name).find { |i| i.name == async_index.name }

          Gitlab::Database::ForeignKeyIndexSupport.new(connection)
            .assert_index_not_last_supporting_foreign_key!(async_index.table_name, index)

          super
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
