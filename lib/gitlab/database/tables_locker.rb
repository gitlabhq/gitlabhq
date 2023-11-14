# frozen_string_literal: true

module Gitlab
  module Database
    class TablesLocker
      GITLAB_SCHEMAS_TO_IGNORE = %i[gitlab_embedding gitlab_geo gitlab_jh].freeze

      def initialize(logger: nil, dry_run: false, include_partitions: true)
        @logger = logger
        @dry_run = dry_run
        @result = []
        @include_partitions = include_partitions
      end

      def unlock_writes
        Gitlab::Database::EachDatabase.each_connection do |connection, database_name|
          tables_to_lock(connection) do |table_name, schema_name|
            # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/366834
            next if schema_name.in? GITLAB_SCHEMAS_TO_IGNORE

            unlock_writes_on_table(table_name, connection, database_name)
          end
        end

        @result
      end

      # It locks the tables on the database where they don't belong. Also it unlocks the tables
      # on the database where they belong
      def lock_writes
        Gitlab::Database::EachDatabase.each_connection(include_shared: false) do |connection, database_name|
          schemas_for_connection = Gitlab::Database.gitlab_schemas_for_connection(connection)

          tables_to_lock(connection) do |table_name, schema_name|
            # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/366834
            next if schema_name.in? GITLAB_SCHEMAS_TO_IGNORE

            if schemas_for_connection.include?(schema_name)
              unlock_writes_on_table(table_name, connection, database_name)
            else
              lock_writes_on_table(table_name, connection, database_name)
            end
          end
        end

        @result
      end

      private

      # Unlocks the writes on the table and its partitions
      def unlock_writes_on_table(table_name, connection, database_name)
        @result << lock_writes_manager(table_name, connection, database_name).unlock_writes
        return unless @include_partitions

        table_attached_partitions(table_name, connection) do |postgres_partition|
          @result << lock_writes_manager(postgres_partition.identifier, connection, database_name).unlock_writes
        end
      end

      # It locks the writes on the table and its partitions
      def lock_writes_on_table(table_name, connection, database_name)
        @result << lock_writes_manager(table_name, connection, database_name).lock_writes
        return unless @include_partitions

        table_attached_partitions(table_name, connection) do |postgres_partition|
          @result << lock_writes_manager(postgres_partition.identifier, connection, database_name).lock_writes
        end
      end

      def tables_to_lock(connection, &block)
        Gitlab::Database::GitlabSchema.tables_to_schema.each(&block)
        return unless @include_partitions

        Gitlab::Database::SharedModel.using_connection(connection) do
          Postgresql::DetachedPartition.find_each do |detached_partition|
            yield detached_partition.fully_qualified_table_name, detached_partition.table_schema
          end
        end
      end

      def table_attached_partitions(table_name, connection, &block)
        Gitlab::Database::SharedModel.using_connection(connection) do
          break unless Gitlab::Database::PostgresPartitionedTable.find_by_name_in_current_schema(table_name)

          Gitlab::Database::PostgresPartitionedTable.each_partition(table_name, &block)
        end
      end

      def lock_writes_manager(table_name, connection, database_name)
        Gitlab::Database::LockWritesManager.new(
          table_name: table_name,
          connection: connection,
          database_name: database_name,
          with_retries: true,
          logger: @logger,
          dry_run: @dry_run
        )
      end
    end
  end
end
