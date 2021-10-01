# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class MultiDatabasePartitionDropper
        def drop_detached_partitions
          Gitlab::AppLogger.info(message: "Dropping detached postgres partitions")

          each_database_connection do |name, connection|
            Gitlab::Database::SharedModel.using_connection(connection) do
              Gitlab::AppLogger.debug(message: "Switched database connection", connection_name: name)

              DetachedPartitionDropper.new.perform
            end
          end

          Gitlab::AppLogger.info(message: "Finished dropping detached postgres partitions")
        end

        private

        def each_database_connection
          databases.each_pair do |name, connection_wrapper|
            yield name, connection_wrapper.scope.connection
          end
        end

        def databases
          Gitlab::Database.databases
        end
      end
    end
  end
end
