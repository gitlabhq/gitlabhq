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

    # We need this code in place, but for now no partitions are allowed because we haven't qualified
    # any partitions that we can test dropping. To "allow" a partition, we need to add an entry to
    # the relevant table's dictionary entry, like this:
    # partition_detach_info:
    # - partition_name: foo_table_100
    #   bounds_clause: "FOR VALUES IN ('100')"
    #   required_constraint: "(partition_id = 100)"
    #   parent_schema: "public"
    #
    # Before we attempt to test detaching a table, we need to ensure that there is a constraint
    # in place sufficient to prevent needing to revalidate the whole partition before reattaching.
    # Also, when the partition is detached, the "bounds clause" is lost, so we document this in the
    # catalog file as well.

    # rubocop:disable Metrics/AbcSize -- Will be moved to its own class
    # rubocop:disable Metrics/CyclomaticComplexity -- Will be moved to its own class
    # rubocop:disable Metrics/PerceivedComplexity -- Will be moved to its own class
    def alter_partition(partition_name, mode, target_database = nil)
      allowed_partitions = Gitlab::Database::Dictionary.entries.find_detach_allowed_partitions

      unless allowed_partitions.key?(partition_name.to_sym)
        puts "#{partition_name} is not listed as one of the allowed partitions, " \
          "only #{allowed_partitions.keys} #{allowed_partitions.keys.length > 1 ? 'are' : 'is'} allowed"
        puts "Please consult the database dictionary files for further info."
        return
      end

      # These two variables are to ensure that we have zero problems qualifying the operation
      # on each database for which we run it. We only want the operation to run if both databases
      # are in the same exact state. If all of the checks on all of the databases pass, only then
      # do we attempt the operation.
      qualifying_partitions = {}
      databases_evaluated = 0

      Gitlab::Database::EachDatabase.each_connection(only: target_database) do |connection, database_name|
        partition_data = Gitlab::TaskHelpers.get_partition_info(partition_name, connection)

        if partition_data.nil?
          puts "Partition #{partition_name} not present on #{database_name}"
          next
        end

        databases_evaluated += 1

        pd = partition_data
        bounds_clause = pd['partition_bounds']

        required_constraint = allowed_partitions[partition_name.to_sym][:required_constraint]
        constraints_on_table = pd['check_constraints'].pluck('raw_check_clause')
        has_necessary_constraint = constraints_on_table.include? required_constraint

        if pd['is_attached'] # We intend to detach
          unless mode == :detach
            puts "Partition #{partition_name} is already attached to #{pd['parent_table']} on #{database_name}"
            next
          end

          # Check that the bounds clause actually exists and is correct, otherwise we can't reattach the partition
          expected_bounds_clause = allowed_partitions[partition_name.to_sym][:bounds_clause]
          if pd['partition_bounds'].nil? || (pd['partition_bounds'] != expected_bounds_clause)
            puts "Bounds clause mismatch, got #{pd['partition_bounds']}, expected #{expected_bounds_clause}"
            next
          end

          bounds_clause = nil
        else # We intend to reattach
          unless mode == :reattach
            parent_table = allowed_partitions[partition_name.to_sym][:parent_table]
            puts "Partition #{partition_name} is not attached to #{parent_table} on #{database_name}"
            next
          end

          bounds_clause = allowed_partitions[partition_name.to_sym][:bounds_clause]
        end

        unless has_necessary_constraint
          puts "#{partition_name} on #{database_name} cannot be safely #{mode}ed because upon reattaching, the " \
            "partition key must be validated, so if a sufficient constraint does not exist, " \
            "we will hold open the requisite lock on the parent table for the duration of this " \
            "validation. Therefore, in order to reattach this partition, we need a constraint with " \
            "the definition #{required_constraint}."
          next
        end

        qualifying_partitions[database_name] = {
          partition_name: partition_name,
          bounds_clause: bounds_clause,
          parent_schema: pd['parent_schema'] || allowed_partitions[partition_name.to_sym][:parent_schema],
          parent_table: pd['parent_table'] || allowed_partitions[partition_name.to_sym][:parent_table],
          target_schema: pd['target_schema'],
          target_partition: pd['target_partition']
        }
      end

      if qualifying_partitions.length == databases_evaluated
        Gitlab::Database::EachDatabase.each_connection(only: target_database) do |connection, database_name|
          p = qualifying_partitions[database_name]
          next if p.nil?

          retry_locker = Gitlab::Database::WithLockRetries.new(
            connection: connection,
            logger: Rails.logger,
            allow_savepoints: false
          )
          retry_locker.run(raise_on_exhaustion: true) do
            table_name_quoted = "#{connection.quote_table_name(p[:parent_schema])}." \
              "#{connection.quote_table_name(p[:parent_table])}"
            partition_name_quoted = "#{connection.quote_table_name(p[:target_schema])}." \
              "#{connection.quote_table_name(p[:target_partition])}"
            connection.execute <<~SQL
              ALTER TABLE #{table_name_quoted}
              #{mode == :reattach ? 'ATTACH' : 'DETACH'} PARTITION #{partition_name_quoted}
              #{p[:bounds_clause]}
            SQL
          end

          puts "Successfully #{mode}ed partition #{p[:target_partition]} on database #{database_name}"
        end
      else
        puts "\x1b[1mThere was an exception\x1b[0m. Please read any output error messages above to " \
          "understand what went wrong."
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Rake/TopLevelMethodDefinition

    desc "GitLab | DB | Detach partition"
    task :detach_partition, [:partition_name] => :environment do |_, args|
      alter_partition(args[:partition_name], :detach)
    end

    desc "GitLab | DB | Reattach partition that has previously been detached"
    task :reattach_partition, [:partition_name] => :environment do |_, args|
      alter_partition(args[:partition_name], :reattach)
    end

    namespace :detach_partition do
      each_database(databases) do |database_name|
        desc "GitLab | DB | Detach partition on the #{database_name} database"
        task database_name, [:partition_name] => :environment do |_, args|
          alter_partition(args[:partition_name], :detach, database_name)
        end
      end
    end

    namespace :reattach_partition do
      each_database(databases) do |database_name|
        desc "GitLab | DB | Reattach partition on the #{database_name} database"
        task database_name, [:partition_name] => :environment do |_, args|
          alter_partition(args[:partition_name], :reattach, database_name)
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
