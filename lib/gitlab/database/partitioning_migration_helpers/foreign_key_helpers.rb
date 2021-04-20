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

        # Creates a "foreign key" that references a partitioned table. Because foreign keys referencing partitioned
        # tables are not supported in PG11, this does not create a true database foreign key, but instead implements the
        # same functionality at the database level by using triggers.
        #
        # Example:
        #
        #   add_partitioned_foreign_key :issues, :projects
        #
        # Available options:
        #
        #   :column - name of the referencing column (otherwise inferred from the referenced table name)
        #   :primary_key - name of the primary key in the referenced table (defaults to id)
        #   :on_delete - supports either :cascade for ON DELETE CASCADE or :nullify for ON DELETE SET NULL
        #
        def add_partitioned_foreign_key(from_table, to_table, column: nil, primary_key: :id, on_delete: :cascade)
          cascade_delete = extract_cascade_option(on_delete)

          update_foreign_keys(from_table, to_table, column, primary_key, cascade_delete) do |current_keys, existing_key, specified_key|
            if existing_key.nil?
              unless specified_key.save
                raise "failed to create foreign key: #{specified_key.errors.full_messages.to_sentence}"
              end

              current_keys << specified_key
            else
              Gitlab::AppLogger.warn "foreign key not added because it already exists: #{specified_key}"
              current_keys
            end
          end
        end

        # Drops a "foreign key" that references a partitioned table. This method ONLY applies to foreign keys previously
        # created through the `add_partitioned_foreign_key` method. Standard database foreign keys should be managed
        # through the familiar Rails helpers.
        #
        # Example:
        #
        #   remove_partitioned_foreign_key :issues, :projects
        #
        # Available options:
        #
        #   :column - name of the referencing column (otherwise inferred from the referenced table name)
        #   :primary_key - name of the primary key in the referenced table (defaults to id)
        #
        def remove_partitioned_foreign_key(from_table, to_table, column: nil, primary_key: :id)
          update_foreign_keys(from_table, to_table, column, primary_key) do |current_keys, existing_key, specified_key|
            if existing_key
              existing_key.delete
              current_keys.delete(existing_key)
            else
              Gitlab::AppLogger.warn "foreign key not removed because it doesn't exist: #{specified_key}"
            end

            current_keys
          end
        end

        private

        def fk_function_name(table)
          object_name(table, 'fk_cascade_function')
        end

        def fk_trigger_name(table)
          object_name(table, 'fk_cascade_trigger')
        end

        def fk_from_spec(from_table, to_table, from_column, to_column, cascade_delete)
          PartitionedForeignKey.new(from_table: from_table.to_s, to_table: to_table.to_s, from_column: from_column.to_s,
                                    to_column: to_column.to_s, cascade_delete: cascade_delete)
        end

        def update_foreign_keys(from_table, to_table, from_column, to_column, cascade_delete = nil)
          assert_not_in_transaction_block(scope: 'partitioned foreign key')

          from_column ||= "#{to_table.to_s.singularize}_id"
          specified_key = fk_from_spec(from_table, to_table, from_column, to_column, cascade_delete)

          current_keys = PartitionedForeignKey.by_referenced_table(to_table).to_a
          existing_key = find_existing_key(current_keys, specified_key)

          final_keys = yield current_keys, existing_key, specified_key

          fn_name = fk_function_name(to_table)
          trigger_name = fk_trigger_name(to_table)

          with_lock_retries do
            drop_trigger(to_table, trigger_name, if_exists: true)

            if final_keys.empty?
              drop_function(fn_name, if_exists: true)
            else
              create_or_replace_fk_function(fn_name, final_keys)
              create_trigger(to_table, trigger_name, fn_name, fires: 'AFTER DELETE')
            end
          end
        end

        def extract_cascade_option(on_delete)
          case on_delete
          when :cascade then true
          when :nullify then false
          else raise ArgumentError, "invalid option #{on_delete} for :on_delete"
          end
        end

        def find_existing_key(keys, key)
          keys.find { |k| k.from_table == key.from_table && k.from_column == key.from_column }
        end

        def create_or_replace_fk_function(fn_name, fk_specs)
          create_trigger_function(fn_name, replace: true) do
            cascade_statements = build_cascade_statements(fk_specs)
            cascade_statements << 'RETURN OLD;'

            cascade_statements.join("\n")
          end
        end

        def build_cascade_statements(foreign_keys)
          foreign_keys.map do |fks|
            if fks.cascade_delete?
              "DELETE FROM #{fks.from_table} WHERE #{fks.from_column} = OLD.#{fks.to_column};"
            else
              "UPDATE #{fks.from_table} SET #{fks.from_column} = NULL WHERE #{fks.from_column} = OLD.#{fks.to_column};"
            end
          end
        end
      end
    end
  end
end
