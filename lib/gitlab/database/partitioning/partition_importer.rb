# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class PartitionImporter
        include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers
        include PartitionKeyColumnTypes
        include EnsureUtcSession

        ImportError = Class.new(StandardError)

        # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
        def initialize(connection:)
          @connection = connection
        end

        # @param table_definitions [Array<Hash>]
        # @param dry_run [Boolean] when true, report what would be created without executing DDL
        # @return [Hash]
        #   { created: Integer, skipped: Integer, tables_processed: Integer }
        def import(table_definitions, dry_run: false)
          ensure_utc_session!

          totals = { created: 0, skipped: 0, tables_processed: 0 }
          errors = []

          table_definitions.each do |table_def|
            process_table(table_def, dry_run: dry_run, totals: totals, errors: errors)
          end

          raise ImportError, error_summary(errors) if errors.any?

          totals
        end

        private

        attr_reader :connection

        def execute(sql)
          @connection.execute(sql)
        end

        def process_table(table_def, dry_run:, totals:, errors:)
          table_name = table_def[:table_name] || table_def['table_name']
          partitions_data = table_def[:partitions] || table_def['partitions'] || []
          partition_type = table_def[:partition_type] || table_def['partition_type']
          partition_strategy = table_def[:partition_strategy] || table_def['partition_strategy']

          return unless connection.table_exists?(table_name)

          totals[:tables_processed] += 1
          missing = missing_partitions(table_name, partitions_data, partition_type, partition_strategy, errors)

          apply_partitions(missing, dry_run: dry_run)
          totals[:created] += missing.size
          totals[:skipped] += partitions_data.size - missing.size
        rescue StandardError => e
          Gitlab::AppLogger.error(
            message: 'Failed to import partitions',
            table_name: table_name,
            exception_class: e.class,
            exception_message: e.message
          )

          errors << format('table=%<table>s error=%<class>s: %<message>s',
            table: table_name,
            class: e.class,
            message: e.message)
        end

        def apply_partitions(partitions, dry_run:)
          return if partitions.empty?

          dry_run ? log_dry_run(partitions) : create_partitions(partitions)
        end

        def missing_partitions(table_name, partitions_data, partition_type, partition_strategy, errors)
          if partition_strategy == 'list' && INTEGER_TYPES.include?(partition_type)
            compute_missing_partitions(table_name, partitions_data, errors,
              partition_class: SingleNumericListPartition)
          elsif INTEGER_TYPES.include?(partition_type)
            compute_missing_partitions(table_name, partitions_data, errors, partition_class: IntRangePartition)
          elsif DATE_TYPES.include?(partition_type)
            compute_missing_partitions(table_name, partitions_data, errors, partition_class: TimePartition)
          else
            []
          end
        end

        def compute_missing_partitions(table_name, partitions_data, errors, partition_class:)
          existing = existing_partitions(table_name, partition_class)

          partitions_data.filter_map do |partition_data|
            partition_name = partition_data[:partition_name] || partition_data['partition_name']

            begin
              parsed_partition = partition_class.from_export_definition(table_name, partition_name, partition_data)
            rescue ArgumentError, TypeError
              errors << track_invalid_partition_definition_error(table_name, partition_name, partition_data)
              next
            end

            next if existing.any? { |e| e.covers?(parsed_partition) }

            parsed_partition
          rescue StandardError => e
            errors << track_invalid_partition_error(table_name, partition_name, partition_data, e)
            nil
          end
        end

        def existing_partitions(table_name, partition_class)
          Gitlab::Database::SharedModel.using_connection(connection) do
            Gitlab::Database::PostgresPartition.for_parent_table(table_name).filter_map do |partition|
              partition_class.from_sql(table_name, partition.name, partition.condition)
            rescue ArgumentError, NotImplementedError
              nil
            end
          end
        end

        def create_partitions(partitions)
          Gitlab::Database::SharedModel.using_connection(connection) do
            WithPartitioningLockRetries.new(
              klass: self.class,
              logger: Gitlab::AppLogger,
              connection: connection
            ).run(raise_on_exhaustion: true) do
              connection.transaction(requires_new: false) do
                partitions.each do |partition|
                  @connection.execute(partition.to_create_sql)
                  @connection.execute(partition.to_attach_sql)
                  process_created_partition(partition)

                  Gitlab::AppLogger.info(
                    message: 'Imported partition',
                    partition_name: partition.partition_name,
                    table_name: partition.table
                  )
                end
              end
            end
          end
        end

        def log_dry_run(partitions)
          partitions.each do |partition|
            Gitlab::AppLogger.info({
              message: 'Dry run: would create partition',
              table_name: partition.table
            }.merge(partition.export_definition))
          end
        end

        def error_summary(errors)
          message = ['Partition import completed with errors:']
          errors.each { |error| message << "- #{error}" }
          message.join("\n")
        end

        def process_created_partition(partition)
          partition_identifier = "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{partition.partition_name}"

          return unless has_loose_foreign_key?(partition.table)

          track_record_deletions_override_table_name(partition_identifier, partition.table)
        end

        def track_invalid_partition_definition_error(table_name, partition_name, partition_data)
          Gitlab::AppLogger.warn(
            message: 'Skipping invalid partition definition',
            table_name: table_name,
            partition_name: partition_name,
            partition_data: partition_data
          )

          format('table=%<table>s partition=%<partition>s data=%<data>p (invalid definition)',
            table: table_name,
            partition: partition_name || 'unknown',
            data: partition_data)
        end

        def track_invalid_partition_error(table_name, partition_name, partition_data, exception)
          Gitlab::AppLogger.warn(
            message: 'Skipping invalid partition bounds',
            table_name: table_name,
            partition_name: partition_name,
            partition_data: partition_data,
            exception_class: exception.class,
            exception_message: exception.message
          )

          format('table=%<table>s partition=%<partition>s data=%<data>p (%<class>s: %<message>s)',
            table: table_name,
            partition: partition_name || 'unknown',
            data: partition_data,
            class: exception.class,
            message: exception.message)
        end
      end
    end
  end
end
