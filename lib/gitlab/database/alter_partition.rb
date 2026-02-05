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

      def detach?
        mode == :detach
      end

      def reattach?
        mode == :reattach
      end

      def valid_for_mode?(partition_data, database_name)
        return false unless valid_attachment_state?(partition_data, database_name)
        return false unless valid_constraints?(partition_data, database_name)

        true
      end

      def valid_attachment_state?(partition_data, database_name)
        if partition_data['is_attached']
          return true if detach?

          log("Partition #{partition_name} is already attached to #{partition_data['parent_table']} " \
            "on #{database_name}")
          return false
        end

        return true if reattach?

        log("Partition #{partition_name} is not attached to #{partition_config[:parent_table]} on #{database_name}")
        false
      end

      def valid_constraints?(partition_data, database_name)
        if detach?
          expected_bounds_clause = partition_config[:bounds_clause]

          if partition_data['partition_bounds'].nil? || partition_data['partition_bounds'] != expected_bounds_clause
            log("Bounds clause mismatch, got #{partition_data['partition_bounds']}, expected #{expected_bounds_clause}")
            return false
          end

          return true
        end

        required_constraint = partition_config[:required_constraint]
        constraints_on_table = partition_data['check_constraints'].pluck('raw_check_clause')

        return true if constraints_on_table.include?(required_constraint)

        log("#{partition_name} on #{database_name} cannot be safely reattached because upon reattaching, the " \
          "partition key must be validated, so if a sufficient constraint does not exist, " \
          "we will hold open the requisite lock on the parent table for the duration of this " \
          "validation. Therefore, in order to reattach this partition, we need a constraint with " \
          "the definition #{required_constraint}.")
        false
      end

      def alter_partition(connection, database_name, partition_data)
        partition_info = build_partition_info(partition_data)

        if detach?
          detach_partition(connection, partition_info)
        else
          attach_partition(connection, partition_info)
        end

        log("Successfully #{mode}ed partition #{partition_info[:target_partition]} on database #{database_name}")
      end

      def detach_partition(connection, partition_info)
        if pending_detach?(connection, partition_info)
          log("Partition #{partition_info[:target_partition]} has pending detach, finalizing...")
          finalize_detach(connection, partition_info)
        else
          connection.execute(build_detach_sql(connection, partition_info))
        end
      end

      def pending_detach?(connection, partition_info)
        connection.select_value(<<~SQL)
          SELECT inh.inhdetachpending
          FROM pg_catalog.pg_inherits inh
          JOIN pg_catalog.pg_class child ON inh.inhrelid = child.oid
          JOIN pg_catalog.pg_namespace child_ns ON child.relnamespace = child_ns.oid
          JOIN pg_catalog.pg_class parent ON inh.inhparent = parent.oid
          WHERE child.relname = #{connection.quote(partition_info[:target_partition])}
            AND child_ns.nspname = #{connection.quote(partition_info[:target_schema])}
            AND parent.relname = #{connection.quote(partition_info[:parent_table])}
        SQL
      end

      def attach_partition(connection, partition_info)
        execute_with_lock_retries(connection, build_attach_sql(connection, partition_info))
      end

      def finalize_detach(connection, partition_info)
        execute_with_lock_retries(connection, build_finalize_sql(connection, partition_info))
      end

      def execute_with_lock_retries(connection, sql)
        locking_config = locking_configuration(connection)
        lock_statement = locking_config.locking_statement_for(lock_tables || [])
        full_sql = lock_statement.present? ? "#{lock_statement.chomp};\n#{sql}" : sql

        WithLockRetries.new(
          connection: connection,
          logger: Gitlab::AppJsonLogger,
          allow_savepoints: false,
          timing_configuration: locking_config.lock_timing_configuration
        ).run(raise_on_exhaustion: true) do
          connection.execute(full_sql)
        end
      end

      def build_detach_sql(connection, partition_info)
        <<~SQL
          ALTER TABLE #{quoted_table_name(connection, partition_info)}
          DETACH PARTITION #{quoted_partition_name(connection, partition_info)} CONCURRENTLY
        SQL
      end

      def build_finalize_sql(connection, partition_info)
        <<~SQL
          ALTER TABLE #{quoted_table_name(connection, partition_info)}
          DETACH PARTITION #{quoted_partition_name(connection, partition_info)} FINALIZE
        SQL
      end

      def build_attach_sql(connection, partition_info)
        <<~SQL
          ALTER TABLE #{quoted_table_name(connection, partition_info)}
          ATTACH PARTITION #{quoted_partition_name(connection, partition_info)}
          #{partition_info[:bounds_clause]}
        SQL
      end

      def locking_configuration(connection)
        Partitioning::List::LockingConfiguration.new(
          connection,
          table_locking_order: lock_tables || []
        )
      end

      def lock_tables
        partition_config[:lock_tables]
      end

      def quoted_table_name(connection, partition_info)
        "#{connection.quote_table_name(partition_info[:parent_schema])}." \
          "#{connection.quote_table_name(partition_info[:parent_table])}"
      end

      def quoted_partition_name(connection, partition_info)
        "#{connection.quote_table_name(partition_info[:target_schema])}." \
          "#{connection.quote_table_name(partition_info[:target_partition])}"
      end

      def build_partition_info(partition_data)
        {
          partition_name: partition_name,
          bounds_clause: reattach? ? partition_config[:bounds_clause] : nil,
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
