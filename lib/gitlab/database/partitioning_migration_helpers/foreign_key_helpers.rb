# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      module ForeignKeyHelpers
        include ::Gitlab::Database::SchemaHelpers

        # Adds a foreign key with only minimal locking on the tables involved.
        #
        # In concept it works similarly to add_concurrent_foreign_key, but we have
        # to add a special helper for partitioned tables for the following reasons:
        # - add_concurrent_foreign_key sets the constraint to `NOT VALID`
        #   before validating it
        # - Setting an FK to NOT VALID is not supported currently in Postgres (up to PG13)
        # - Also, PostgreSQL will currently ignore NOT VALID constraints on partitions
        #   when adding a valid FK to the partitioned table, so they have to
        #   also be validated before we can add the final FK.
        # Solution:
        # - Add the foreign key first to each partition by using
        #   add_concurrent_foreign_key and validating it
        # - Once all partitions have a foreign key, add it also to the partitioned
        #   table (there will be no need for a validation at that level)
        # For those reasons, this method does not include an option to delay the
        # validation, we have to force validate: true.
        #
        # source - The source (partitioned) table containing the foreign key.
        # target - The target table the key points to.
        # column - The name of the column to create the foreign key on.
        # on_delete - The action to perform when associated data is removed,
        #             defaults to "CASCADE".
        # name - The name of the foreign key.
        #
        def add_concurrent_partitioned_foreign_key(source, target, column:, on_delete: :cascade, name: nil)
          partition_options = {
            column: column,
            on_delete: on_delete,

            # We'll use the same FK name for all partitions and match it to
            # the name used for the partitioned table to follow the convention
            # used by PostgreSQL when adding FKs to new partitions
            name: name.presence || concurrent_partitioned_foreign_key_name(source, column),

            # Force the FK validation to true for partitions (and the partitioned table)
            validate: true
          }

          if foreign_key_exists?(source, target, **partition_options)
            warning_message = "Foreign key not created because it exists already " \
              "(this may be due to an aborted migration or similar): " \
              "source: #{source}, target: #{target}, column: #{partition_options[:column]}, "\
              "name: #{partition_options[:name]}, on_delete: #{partition_options[:on_delete]}"

            Gitlab::AppLogger.warn warning_message

            return
          end

          partitioned_table = find_partitioned_table(source)

          partitioned_table.postgres_partitions.order(:name).each do |partition|
            add_concurrent_foreign_key(partition.identifier, target, **partition_options)
          end

          with_lock_retries do
            add_foreign_key(source, target, **partition_options)
          end
        end

        # Returns the name for a concurrent partitioned foreign key.
        #
        # Similar to concurrent_foreign_key_name (Gitlab::Database::MigrationHelpers)
        # we just keep a separate method in case we want a different behavior
        # for partitioned tables
        #
        def concurrent_partitioned_foreign_key_name(table, column, prefix: 'fk_rails_')
          identifier = "#{table}_#{column}_fk"
          hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)

          "#{prefix}#{hashed_identifier}"
        end
      end
    end
  end
end
