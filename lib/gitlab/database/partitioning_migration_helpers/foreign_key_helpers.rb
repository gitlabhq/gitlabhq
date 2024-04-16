# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      module ForeignKeyHelpers
        include ::Gitlab::Database::SchemaHelpers
        include ::Gitlab::Database::Migrations::LockRetriesHelpers
        include ::Gitlab::Database::MigrationHelpers::Swapping

        ERROR_SCOPE = 'foreign keys'

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
        # on_update - The action to perform when associated data is updated,
        #             no default value is set.
        # name - The name of the foreign key.
        # validate - Flag that controls whether the new foreign key will be
        #            validated after creation and if it will be added on the parent table.
        #            If the flag is not set, the constraint will only be enforced for new data
        #            in the existing partitions. The helper will need to be called again
        #            with the flag set to `true` to add the foreign key on the parent table
        #            after validating it on all partitions.
        #            `validate: false` should be paired with `prepare_partitioned_async_foreign_key_validation`
        # reverse_lock_order - Flag that controls whether we should attempt to acquire locks in the reverse
        #                      order of the ALTER TABLE. This can be useful in situations where the foreign
        #                      key creation could deadlock with another process.
        #
        def add_concurrent_partitioned_foreign_key(source, target, column:, **options)
          assert_not_in_transaction_block(scope: ERROR_SCOPE)

          options.reverse_merge!({
            target_column: :id,
            on_delete: :cascade,
            on_update: nil,
            name: nil,
            validate: true,
            reverse_lock_order: false,
            column: column
          })

          # We'll use the same FK name for all partitions and match it to
          # the name used for the partitioned table to follow the convention
          # used by PostgreSQL when adding FKs to new partitions
          options[:name] ||= concurrent_partitioned_foreign_key_name(source, column)
          check_options = options.slice(:column, :on_delete, :on_update, :name)
          check_options[:primary_key] = options[:target_column]

          if foreign_key_exists?(source, target, **check_options)
            warning_message = "Foreign key not created because it exists already " \
              "(this may be due to an aborted migration or similar): " \
              "source: #{source}, target: #{target}, column: #{options[:column]}, "\
              "name: #{options[:name]}, on_delete: #{options[:on_delete]}, "\
              "on_update: #{options[:on_update]}"

            Gitlab::AppLogger.warn warning_message

            return
          end

          Gitlab::Database::PostgresPartitionedTable.each_partition(source) do |partition|
            add_concurrent_foreign_key(partition.identifier, target, **options)
          end

          # If we are to add the FK on the parent table now, it will trigger
          # the validation on all partitions. The helper must be called one
          # more time with `validate: true` after the FK is valid on all partitions.
          return unless options[:validate]

          options[:allow_partitioned] = true
          add_concurrent_foreign_key(source, target, **options)
        end

        def validate_partitioned_foreign_key(source, column, name: nil)
          assert_not_in_transaction_block(scope: ERROR_SCOPE)

          fk_name = name || concurrent_partitioned_foreign_key_name(source, column)

          Gitlab::Database::PostgresPartitionedTable.each_partition(source) do |partition|
            unless foreign_key_exists?(partition.identifier, name: fk_name)
              Gitlab::AppLogger.warn("Missing #{fk_name} on #{partition.identifier}")
              next
            end

            validate_foreign_key(partition.identifier, column, name: fk_name)
          end
        end

        # Rename the foreign key for partitioned table and its partitions.
        #
        # Example:
        #
        #     rename_partitioned_foreign_key :users, 'existing_partitioned_fk_name', 'new_fk_name'
        def rename_partitioned_foreign_key(table_name, old_foreign_key, new_foreign_key)
          partitioned_table = find_partitioned_table(table_name)
          partitioned_table.postgres_partitions.order(:name).each do |partition|
            rename_constraint(partition.identifier, old_foreign_key, new_foreign_key)
          end

          rename_constraint(partitioned_table.name, old_foreign_key, new_foreign_key)
        end

        # Swap the foreign key names for partitioned table and its partitions.
        #
        # Example:
        #
        #     swap_partitioned_foreign_keys :users, 'existing_partitioned_fk_name_1', 'existing_partitioned_fk_name_2'
        def swap_partitioned_foreign_keys(table_name, old_foreign_key, new_foreign_key)
          partitioned_table = find_partitioned_table(table_name)
          partitioned_table.postgres_partitions.order(:name).each do |partition|
            swap_foreign_keys(partition.identifier, old_foreign_key, new_foreign_key)
          end

          swap_foreign_keys(partitioned_table.name, old_foreign_key, new_foreign_key)
        end

        private

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
