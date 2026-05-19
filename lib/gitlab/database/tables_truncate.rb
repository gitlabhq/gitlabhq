# frozen_string_literal: true

module Gitlab
  module Database
    class TablesTruncate
      GITLAB_SCHEMAS_TO_IGNORE = %i[gitlab_geo gitlab_embedding gitlab_jh].freeze

      def initialize(database_name:, min_batch_size: 5, logger: nil, until_table: nil, dry_run: false)
        @database_name = database_name
        @min_batch_size = min_batch_size
        @logger = logger
        @until_table = until_table
        @dry_run = dry_run
      end

      def execute
        raise "Cannot truncate legacy tables in single-db setup" if single_database_setup?
        raise "database is not supported" unless %w[main ci sec].include?(database_name)

        logger&.info "DRY RUN:" if dry_run

        tables_sorted = Gitlab::Database::TablesSortedByForeignKeys.new(connection, tables_to_truncate).execute
        # Checking if all the tables have the write-lock triggers
        # to make sure we are deleting the right tables on the right database.
        tables_sorted.flatten.each do |table_name|
          lock_writes_manager = Gitlab::Database::LockWritesManager.new(
            table_name: table_name,
            connection: connection,
            database_name: database_name,
            with_retries: true,
            logger: logger,
            dry_run: dry_run
          )

          unless lock_writes_manager.table_locked_for_writes?
            raise "Table '#{table_name}' is not locked for writes. Run the rake task gitlab:db:lock_writes first"
          end
        end

        if until_table
          table_index = tables_sorted.find_index { |tables_group| tables_group.include?(until_table) }
          raise "The table '#{until_table}' is not within the truncated tables" if table_index.nil?

          tables_sorted = tables_sorted[0..table_index]
        end

        # min_batch_size is the minimum number of new tables to truncate at each stage.
        # But in each stage we have also have to truncate the already truncated tables in the previous stages
        logger&.info "Truncating legacy tables for the database #{database_name}"
        truncate_tables_in_batches(tables_sorted)
      end

      def needs_truncation?
        return false if single_database_setup?

        sql = tables_to_truncate.map { |table_name| "(SELECT EXISTS( SELECT * FROM #{table_name} ))" }.join("\nUNION\n")

        result = with_suppressed_query_analyzers do
          connection.execute(sql).to_a
        end

        result.to_a.any? { |row| row['exists'] == true }
      end

      private

      attr_accessor :database_name, :min_batch_size, :logger, :dry_run, :until_table

      def tables_to_truncate
        @tables_to_truncate ||= begin
          schemas_for_connection = Gitlab::Database.gitlab_schemas_for_connection(connection)
          tables = Gitlab::Database::GitlabSchema.tables_to_schema.reject do |_, schema_name|
            GITLAB_SCHEMAS_TO_IGNORE.union(schemas_for_connection).include?(schema_name)
          end.keys

          Gitlab::Database::SharedModel.using_connection(connection) do
            Postgresql::DetachedPartition.find_each do |detached_partition|
              next if GITLAB_SCHEMAS_TO_IGNORE.union(schemas_for_connection).include?(detached_partition.table_schema)

              tables << detached_partition.fully_qualified_table_name
            end
          end

          # Skip tables that don't physically exist on this connection. Newer
          # databases (e.g. sec) never had legacy CI/main tables, and stale
          # detached_partitions rows may reference already-dropped tables.
          tables.select { |t| existing_tables_set.include?(t) }
        end
      end

      def existing_tables_set
        @existing_tables_set ||= begin
          sql = <<~SQL
            SELECT table_schema, table_name
            FROM information_schema.tables
            WHERE table_type = 'BASE TABLE'
          SQL
          current_schema = connection.current_schema
          connection.exec_query(sql).rows.each_with_object(Set.new) do |(schema, name), set|
            # Unqualified names resolve via search_path; only include for current_schema.
            set << name if schema == current_schema
            set << "#{schema}.#{name}"
          end
        end
      end

      def connection
        @connection ||= Gitlab::Database.database_base_models[database_name].connection
      end

      def remove_schema_name(table_with_schema)
        ActiveRecord::ConnectionAdapters::PostgreSQL::Utils
          .extract_schema_qualified_name(table_with_schema)
          .identifier
      end

      def disable_locks_on_table(table)
        sql_statement = "SELECT set_config('lock_writes.#{table}', 'false', false)"
        logger&.info(sql_statement)
        connection.execute(sql_statement) unless dry_run
      end

      def truncate_tables_in_batches(tables_sorted)
        truncated_tables = []

        tables_sorted.flatten.each do |table|
          table_name_without_schema = remove_schema_name(table)

          disable_locks_on_table(table_name_without_schema)

          # Temporarily unlocking writes on the attached partitions of the table.
          # Because in some cases they might have been locked for writes as well, when they used to be
          # normal tables before being converted into attached partitions.
          Gitlab::Database::SharedModel.using_connection(connection) do
            table_partitions = Gitlab::Database::PostgresPartition.for_parent_table(table_name_without_schema)
            table_partitions.each do |table_partition|
              disable_locks_on_table(remove_schema_name(table_partition.identifier))
            end
          end
        end

        # Find tables with FK constraints pointing to our truncation list that are absent
        # from the schema docs. These are tables removed from the docs (e.g. pending a DROP
        # migration) but still present in the database. PostgreSQL requires them to appear in
        # the same TRUNCATE statement as the tables they reference.
        extra_fk_tables = unregistered_fk_referencing_tables(tables_sorted.flatten)
          .select { |t| existing_tables_set.include?(t) }
        extra_fk_tables.each do |table|
          disable_locks_on_table(table)

          # Disable write locks on attached partitions too, otherwise TRUNCATE
          # of a partitioned parent fires the partition's write-lock trigger.
          Gitlab::Database::SharedModel.using_connection(connection) do
            Gitlab::Database::PostgresPartition.for_parent_table(table).each do |partition|
              disable_locks_on_table(remove_schema_name(partition.identifier))
            end
          end
        end

        # We do the truncation in stages to avoid high IO
        # In each stage, we truncate the new tables along with the already truncated
        # tables before. That's because PostgreSQL doesn't allow to truncate any table (A)
        # without truncating any other table (B) that has a Foreign Key pointing to the table (A).
        # even if table (B) is empty, because it has been already truncated in a previous stage.
        tables_sorted.in_groups_of(min_batch_size, false).each do |tables_groups|
          new_tables_to_truncate = tables_groups.flatten
          logger&.info "= New tables to truncate: #{new_tables_to_truncate.join(', ')}"
          truncated_tables.push(*new_tables_to_truncate).tap(&:sort!)
          all_tables = (truncated_tables + extra_fk_tables).sort
          sql_statements = [
            "SET LOCAL statement_timeout = 0",
            "SET LOCAL lock_timeout = 0",
            "TRUNCATE TABLE #{all_tables.join(', ')} RESTRICT"
          ]

          sql_statements.each { |sql_statement| logger&.info(sql_statement) }

          next if dry_run

          connection.transaction do
            sql_statements.each { |sql_statement| connection.execute(sql_statement) }
          end
        end
      end

      # Returns tables that have FK constraints pointing to any table in +tables+ but are
      # absent from the schema docs. Walks FK chains transitively so that multi-hop
      # dependencies are also captured.
      def unregistered_fk_referencing_tables(tables)
        schemas_for_connection = Gitlab::Database.gitlab_schemas_for_connection(connection)
        ignored_schemas = GITLAB_SCHEMAS_TO_IGNORE.union(schemas_for_connection)
        owned_tables = Gitlab::Database::GitlabSchema.tables_to_schema.select do |_, schema_name|
          ignored_schemas.include?(schema_name)
        end.keys

        extra_tables = []

        Gitlab::Database::SharedModel.using_connection(connection) do
          # After detachment, a partition's FK constraints are no longer marked as
          # inherited, so .not_inherited does not filter them out. Exclude explicitly.
          detached_partition_names = Postgresql::DetachedPartition.pluck(:table_name)

          # `tables` may contain schema-qualified names (e.g. for detached partitions)
          # but constrained_table_name and referenced_table_name are always unqualified.
          tables_unqualified = tables.map { |t| remove_schema_name(t) }
          current_scope = tables_unqualified.dup

          loop do
            excluded = tables_unqualified + extra_tables + owned_tables + detached_partition_names
            newly_found = Gitlab::Database::PostgresForeignKey
              .not_inherited
              .by_referenced_table_name(current_scope)
              .where.not(constrained_table_name: excluded)
              .pluck(:constrained_table_name)
              .uniq

            break if newly_found.empty?

            extra_tables.concat(newly_found)
            current_scope = newly_found
          end
        end

        extra_tables
      end

      def single_database_setup?
        return true unless Gitlab::Database.has_config?(:ci)

        ci_base_model = Gitlab::Database.database_base_models[:ci]
        !!Gitlab::Database.db_config_share_with(ci_base_model.connection_db_config)
      end

      def with_suppressed_query_analyzers(&block)
        Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
          Gitlab::Database::QueryAnalyzers::Ci::PartitioningRoutingAnalyzer.with_suppressed(&block)
        end
      end
    end
  end
end
