# frozen_string_literal: true

module Gitlab
  module Database
    class TablesLocker
      GITLAB_SCHEMAS_TO_IGNORE = %i[gitlab_geo].freeze

      def initialize(logger: nil, dry_run: false)
        @logger = logger
        @dry_run = dry_run
      end

      def unlock_writes
        Gitlab::Database::EachDatabase.each_database_connection do |connection, database_name|
          tables_to_lock(connection) do |table_name, schema_name|
            # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/366834
            next if schema_name.in? GITLAB_SCHEMAS_TO_IGNORE

            lock_writes_manager(table_name, connection, database_name).unlock_writes
          end
        end
      end

      def lock_writes
        Gitlab::Database::EachDatabase.each_database_connection(include_shared: false) do |connection, database_name|
          schemas_for_connection = Gitlab::Database.gitlab_schemas_for_connection(connection)

          tables_to_lock(connection) do |table_name, schema_name|
            # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/366834
            next if schema_name.in? GITLAB_SCHEMAS_TO_IGNORE

            if schemas_for_connection.include?(schema_name)
              lock_writes_manager(table_name, connection, database_name).unlock_writes
            else
              lock_writes_manager(table_name, connection, database_name).lock_writes
            end
          end
        end
      end

      private

      def tables_to_lock(connection, &block)
        Gitlab::Database::GitlabSchema.tables_to_schema.each(&block)

        Gitlab::Database::SharedModel.using_connection(connection) do
          Postgresql::DetachedPartition.find_each do |detached_partition|
            yield detached_partition.fully_qualified_table_name, detached_partition.table_schema
          end
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
