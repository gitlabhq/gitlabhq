# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module PreparedAsyncDmlOperationsTesting
        module AsyncIndexMixin
          extend ActiveSupport::Concern

          def prepare_async_index(...)
            mark_for_testing_execution(super)
          end

          def prepare_async_index_from_sql(...)
            mark_for_testing_execution(super)
          end

          private

          def mark_for_testing_execution(async_index)
            return unless async_index

            async_index.update!(definition: "#{async_index.definition} /* SYNC_TESTING_EXECUTION */")
          end
        end

        class AsyncOperationsRunner
          class << self
            def install!
              Gitlab::Database::AsyncIndexes::MigrationHelpers.prepend(AsyncIndexMixin)
            end

            def execute!
              indexes_to_create.each do |async_index|
                PreparedAsyncDmlOperationsTesting::IndexCreator.new(async_index).perform
              end
            end

            private

            def indexes_to_create
              Gitlab::Database::AsyncIndexes::PostgresAsyncIndex.to_create.where(
                "definition LIKE '%/* SYNC_TESTING_EXECUTION */%'"
              )
            end
          end
        end
      end
    end
  end
end
