# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class MultiDatabasePartitionManager
        def initialize(models)
          @models = models
        end

        def sync_partitions
          Gitlab::AppLogger.info(message: "Syncing dynamic postgres partitions")

          models.each do |model|
            Gitlab::Database::SharedModel.using_connection(model.connection) do
              Gitlab::AppLogger.debug(message: "Switched database connection",
                                      connection_name: connection_name,
                                      table_name: model.table_name)

              PartitionManager.new(model).sync_partitions
            end
          end

          Gitlab::AppLogger.info(message: "Finished sync of dynamic postgres partitions")
        end

        private

        attr_reader :models

        def connection_name
          Gitlab::Database::SharedModel.connection.pool.db_config.name
        end
      end
    end
  end
end
