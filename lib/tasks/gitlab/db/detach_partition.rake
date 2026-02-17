# frozen_string_literal: true

databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

namespace :gitlab do
  namespace :db do
    # rubocop:disable Rake/TopLevelMethodDefinition -- Instance methods within task scope do not leak
    def each_database(databases, include_geo: false)
      ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |database|
        next if database == 'embedding'
        next if database == 'jh'
        next if !include_geo && database == 'geo'

        yield database
      end
    end
    # rubocop:enable Rake/TopLevelMethodDefinition

    # To "allow" a partition, we need to add an entry to the relevant table's dictionary entry, like this:
    # partition_detach_info:
    # - partition_name: foo_table_100
    #   bounds_clause: "FOR VALUES IN ('100')"
    #   required_constraint: "(partition_id = 100)"
    #   parent_schema: "public"
    #
    # To find the correct required_constraint value:
    # 1. Detach the partition on Database Lab first using DETACH CONCURRENTLY
    #      pgai use -o ci -- bin/rake 'gitlab:db:detach_partition:ci[foo_table_100]'
    # 2. Query the existing validated constraints:
    #      SELECT pg_get_constraintdef(oid)
    #      FROM pg_constraint
    #      WHERE conrelid = 'gitlab_partitions_dynamic.foo_table_100'::regclass
    #        AND contype = 'c';

    desc "GitLab | DB | Detach partition"
    task :detach_partition, [:partition_name] => :environment do |_, args|
      Gitlab::Database::AlterPartition.new(args[:partition_name], :detach).execute
    end

    desc "GitLab | DB | Reattach partition that has previously been detached"
    task :reattach_partition, [:partition_name] => :environment do |_, args|
      Gitlab::Database::AlterPartition.new(args[:partition_name], :reattach).execute
    end

    namespace :detach_partition do
      each_database(databases) do |database_name|
        desc "GitLab | DB | Detach partition on the #{database_name} database"
        task database_name, [:partition_name] => :environment do |_, args|
          Gitlab::Database::AlterPartition.new(args[:partition_name], :detach, target_database: database_name).execute
        end
      end
    end

    namespace :reattach_partition do
      each_database(databases) do |database_name|
        desc "GitLab | DB | Reattach partition on the #{database_name} database"
        task database_name, [:partition_name] => :environment do |_, args|
          Gitlab::Database::AlterPartition.new(args[:partition_name], :reattach, target_database: database_name).execute
        end
      end
    end

    desc "GitLab | DB | Truncate detached partition"
    task :truncate_partition, [:partition_name] => :environment do |_, args|
      Gitlab::Database::TruncatePartition.new(args[:partition_name]).execute
    end

    namespace :truncate_partition do
      each_database(databases) do |database_name|
        desc "GitLab | DB | Truncate detached partition on the #{database_name} database"
        task database_name, [:partition_name] => :environment do |_, args|
          Gitlab::Database::TruncatePartition.new(args[:partition_name], target_database: database_name).execute
        end
      end
    end

    desc "GitLab | DB | Detach ci_builds_metadata partitions 103-107"
    task detach_ci_builds_metadata_partitions: :environment do
      partition_range = (103..107).to_a
      parent_tables = %w[p_ci_builds p_ci_builds_metadata]

      Gitlab::Database::EachDatabase.each_connection(only: 'ci') do |connection|
        lock_statements = parent_tables.map do |table_name|
          "LOCK TABLE #{connection.quote_table_name(table_name)} IN ACCESS EXCLUSIVE MODE;"
        end

        statements = partition_range.map do |partition_num|
          partition_name = "gitlab_partitions_dynamic.ci_builds_metadata_#{partition_num}"

          "ALTER TABLE p_ci_builds_metadata DETACH PARTITION #{connection.quote_table_name(partition_name)};"
        end

        sql_query = (lock_statements + statements).join("\n")
        iterations = Gitlab::Database::WithLockRetries::DEFAULT_TIMING_CONFIGURATION
        aggressive_iterations = Array.new(5) { [10.seconds, 1.minute] }
        retry_locker = Gitlab::Database::WithLockRetries.new(
          connection: connection,
          logger: Gitlab::AppJsonLogger,
          allow_savepoints: false,
          timing_configuration: iterations + aggressive_iterations
        )

        retry_locker.run(raise_on_exhaustion: true) do
          connection.execute(sql_query)
        end

        puts 'Detached p_ci_builds_metadata partitions'
        Gitlab::AppJsonLogger.info(message: 'Detached p_ci_builds_metadata partitions')
      end
    end

    desc "GitLab | DB | Attach ci_builds_metadata partitions 103-107"
    task attach_ci_builds_metadata_partitions: :environment do
      partition_range = (103..107).to_a
      parent_tables = %w[p_ci_builds p_ci_builds_metadata]

      Gitlab::Database::EachDatabase.each_connection(only: 'ci') do |connection|
        lock_statements = parent_tables.map do |table_name|
          "LOCK TABLE #{connection.quote_table_name(table_name)} IN ACCESS EXCLUSIVE MODE;"
        end

        statements = partition_range.map do |partition_num|
          partition_name = connection.quote_table_name("gitlab_partitions_dynamic.ci_builds_metadata_#{partition_num}")
          partition_value = connection.quote(partition_num)

          "ALTER TABLE p_ci_builds_metadata ATTACH PARTITION #{partition_name} FOR VALUES IN (#{partition_value});"
        end

        sql_query = (lock_statements + statements).join("\n")
        iterations = Gitlab::Database::WithLockRetries::DEFAULT_TIMING_CONFIGURATION
        aggressive_iterations = Array.new(5) { [10.seconds, 1.minute] }
        retry_locker = Gitlab::Database::WithLockRetries.new(
          connection: connection,
          logger: Gitlab::AppJsonLogger,
          allow_savepoints: false,
          timing_configuration: iterations + aggressive_iterations
        )

        retry_locker.run(raise_on_exhaustion: true) do
          connection.execute(sql_query)
        end

        puts 'Attached p_ci_builds_metadata partitions'
        Gitlab::AppJsonLogger.info(message: 'Attached p_ci_builds_metadata partitions')
      end
    end
  end
end
