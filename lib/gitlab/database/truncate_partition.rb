# frozen_string_literal: true

module Gitlab
  module Database
    class TruncatePartition
      def initialize(partition_name, target_database: nil, logger: Logger.new($stdout))
        @partition_name = partition_name
        @target_database = target_database
        @logger = logger
      end

      def execute
        unless allowed_partition?
          log("#{partition_name} is not listed as one of the allowed partitions, " \
            "only #{allowed_partitions.keys.join(', ')} allowed")
          return false
        end

        success = true

        EachDatabase.each_connection(only: target_database) do |connection, database_name|
          partition_data = TaskHelpers.get_partition_info(partition_name, connection)

          if partition_data.nil?
            log("Partition #{partition_name} not present on #{database_name}")
            next
          end

          if partition_data['is_attached']
            log("Partition #{partition_name} is still attached on #{database_name}. Detach before truncating.")
            success = false
            next
          end

          truncate(connection, partition_data, database_name)
        end

        success
      end

      private

      attr_reader :partition_name, :target_database, :logger

      def allowed_partitions
        @allowed_partitions ||= Dictionary.entries.find_detach_allowed_partitions
      end

      def allowed_partition?
        allowed_partitions.key?(partition_name.to_sym)
      end

      def truncate(connection, partition_data, database_name)
        partition_name_quoted = "#{connection.quote_table_name(partition_data['target_schema'])}." \
          "#{connection.quote_table_name(partition_data['target_partition'])}"

        WithLockRetries.new(
          connection: connection,
          logger: Gitlab::AppLogger,
          allow_savepoints: false
        ).run(raise_on_exhaustion: true) do
          connection.execute("TRUNCATE #{partition_name_quoted}")
        end

        log("Successfully truncated partition #{partition_name} on database #{database_name}")
      end

      def log(message)
        logger.info message
      end
    end
  end
end
