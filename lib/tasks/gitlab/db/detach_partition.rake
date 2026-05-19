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
  end
end
