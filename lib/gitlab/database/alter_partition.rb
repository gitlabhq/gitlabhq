# frozen_string_literal: true

module Gitlab
  module Database
    class AlterPartition
      def initialize(partition_name, mode, target_database: nil, logger: Logger.new($stdout))
        @partition_name = partition_name
        @mode = mode
        @target_database = target_database
        @logger = logger
      end

      def execute
        unless allowed_partition?
          log("#{partition_name} is not listed as one of the allowed partitions, " \
            "only #{allowed_partitions.keys} #{allowed_partitions.keys.length > 1 ? 'are' : 'is'} allowed")
          log("Please consult the database dictionary files for further info.")
          return false
        end

        success = false

        EachDatabase.each_connection(only: target_database) do |connection, database_name|
          partition_data = TaskHelpers.get_partition_info(partition_name, connection)

          if partition_data.nil?
            log("Partition #{partition_name} not present on #{database_name}")
            next
          end

          next unless valid_for_mode?(partition_data, database_name)

          alter_partition(connection, database_name, partition_data)
          success = true
        end

        success
      end

      private

      attr_reader :partition_name, :mode, :target_database, :logger

      def allowed_partitions
        @allowed_partitions ||= Dictionary.entries.find_detach_allowed_partitions
      end

      def allowed_partition?
        allowed_partitions.key?(partition_name.to_sym)
      end

      def partition_config
        allowed_partitions[partition_name.to_sym]
      end

      def valid_for_mode?(partition_data, database_name)
        return false unless valid_attachment_state?(partition_data, database_name)
        return false unless valid_constraints?(partition_data, database_name)

        true
      end

      def valid_attachment_state?(partition_data, database_name)
        if partition_data['is_attached']
          return true if mode == :detach

          log("Partition #{partition_name} is already attached to #{partition_data['parent_table']} " \
            "on #{database_name}")
          return false
        end

        return true if mode == :reattach

        log("Partition #{partition_name} is not attached to #{partition_config[:parent_table]} on #{database_name}")
        false
      end

      def valid_constraints?(partition_data, database_name)
        if mode == :detach
          expected_bounds_clause = partition_config[:bounds_clause]

          if partition_data['partition_bounds'].nil? || partition_data['partition_bounds'] != expected_bounds_clause
            log("Bounds clause mismatch, got #{partition_data['partition_bounds']}, expected #{expected_bounds_clause}")
            return false
          end
        end

        required_constraint = partition_config[:required_constraint]
        constraints_on_table = partition_data['check_constraints'].pluck('raw_check_clause')

        return true if constraints_on_table.include?(required_constraint)

        log("#{partition_name} on #{database_name} cannot be safely #{mode}ed because upon reattaching, the " \
          "partition key must be validated, so if a sufficient constraint does not exist, " \
          "we will hold open the requisite lock on the parent table for the duration of this " \
          "validation. Therefore, in order to reattach this partition, we need a constraint with " \
          "the definition #{required_constraint}.")
        false
      end

      def alter_partition(connection, database_name, partition_data)
        partition_info = build_partition_info(partition_data)
        sql = build_alter_sql(connection, partition_info)

        WithLockRetries.new(
          connection: connection,
          logger: Gitlab::AppJsonLogger,
          allow_savepoints: false
        ).run(raise_on_exhaustion: true) do
          connection.execute(sql)
        end

        log("Successfully #{mode}ed partition #{partition_info[:target_partition]} on database #{database_name}")
      end

      def build_alter_sql(connection, partition_info)
        table_name_quoted = "#{connection.quote_table_name(partition_info[:parent_schema])}." \
          "#{connection.quote_table_name(partition_info[:parent_table])}"
        partition_name_quoted = "#{connection.quote_table_name(partition_info[:target_schema])}." \
          "#{connection.quote_table_name(partition_info[:target_partition])}"

        <<~SQL
          ALTER TABLE #{table_name_quoted}
          #{mode == :reattach ? 'ATTACH' : 'DETACH'} PARTITION #{partition_name_quoted}
          #{partition_info[:bounds_clause]}
        SQL
      end

      def build_partition_info(partition_data)
        {
          partition_name: partition_name,
          bounds_clause: mode == :reattach ? partition_config[:bounds_clause] : nil,
          parent_schema: partition_data['parent_schema'] || partition_config[:parent_schema],
          parent_table: partition_data['parent_table'] || partition_config[:parent_table],
          target_schema: partition_data['target_schema'],
          target_partition: partition_data['target_partition']
        }
      end

      def log(message)
        logger.info message
      end
    end
  end
end
