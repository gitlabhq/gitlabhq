# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module ConstraintsHelpers
        include LockRetriesHelpers
        include TimeoutHelpers

        # https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIERS
        MAX_IDENTIFIER_NAME_LENGTH = 63

        def self.check_constraint_exists?(table, constraint_name, connection:)
          table_name, schema_name = table.to_s.split('.').reverse
          schema_name ||= connection.current_schema

          # Constraint names are unique per table in Postgres, not per schema
          # Two tables can have constraints with the same name, so we filter by
          # the table name in addition to using the constraint_name

          check_sql = <<~SQL
            SELECT COUNT(*)
            FROM pg_catalog.pg_constraint con
              INNER JOIN pg_catalog.pg_class rel
                ON rel.oid = con.conrelid
              INNER JOIN pg_catalog.pg_namespace nsp
                ON nsp.oid = con.connamespace
            WHERE con.contype = 'c'
            AND con.conname = #{connection.quote(constraint_name)}
            AND nsp.nspname = #{connection.quote(schema_name)}
            AND rel.relname = #{connection.quote(table_name)}
          SQL

          connection.select_value(check_sql.squish) > 0
        end

        # Returns the name for a check constraint
        #
        # type:
        # - Any value, as long as it is unique
        # - Constraint names are unique per table in Postgres, and, additionally,
        #   we can have multiple check constraints over a column
        #   So we use the (table, column, type) triplet as a unique name
        # - e.g. we use 'max_length' when adding checks for text limits
        #        or 'not_null' when adding a NOT NULL constraint
        #
        def check_constraint_name(table, column, type)
          identifier = "#{table}_#{column}_check_#{type}"
          # Check concurrent_foreign_key_name() for info on why we use a hash
          hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)

          "check_#{hashed_identifier}"
        end

        def check_constraint_exists?(table, constraint_name)
          ConstraintsHelpers.check_constraint_exists?(table, constraint_name, connection: connection)
        end

        # Adds a check constraint to a table
        #
        # This method is the generic helper for adding any check constraint
        # More specialized helpers may use it (e.g. add_text_limit or add_not_null)
        #
        # This method only requires minimal locking:
        # - The constraint is added using NOT VALID
        #   This allows us to add the check constraint without validating it
        # - The check will be enforced for new data (inserts) coming in
        # - If `validate: true` the constraint is also validated
        #   Otherwise, validate_check_constraint() can be used at a later stage
        # - Check comments on add_concurrent_foreign_key for more info
        #
        # table  - The table the constraint will be added to
        # check  - The check clause to add
        #          e.g. 'char_length(name) <= 5' or 'store IS NOT NULL'
        # constraint_name - The name of the check constraint (otherwise auto-generated)
        #                   Should be unique per table (not per column)
        # validate - Whether to validate the constraint in this call
        #
        def add_check_constraint(table, check, constraint_name, validate: true)
          # Transactions would result in ALTER TABLE locks being held for the
          # duration of the transaction, defeating the purpose of this method.
          validate_not_in_transaction!(:add_check_constraint)

          validate_check_constraint_name!(constraint_name)

          if check_constraint_exists?(table, constraint_name)
            warning_message = <<~MESSAGE
              Check constraint was not created because it exists already
              (this may be due to an aborted migration or similar)
              table: #{table}, check: #{check}, constraint name: #{constraint_name}
            MESSAGE

            Gitlab::AppLogger.warn warning_message
          else
            # Only add the constraint without validating it
            # Even though it is fast, ADD CONSTRAINT requires an EXCLUSIVE lock
            # Use with_lock_retries to make sure that this operation
            # will not timeout on tables accessed by many processes
            with_lock_retries do
              execute <<~SQL
              ALTER TABLE #{table}
              ADD CONSTRAINT #{constraint_name}
              CHECK ( #{check} )
              NOT VALID;
              SQL
            end
          end

          validate_check_constraint(table, constraint_name) if validate
        end

        def validate_check_constraint(table, constraint_name)
          validate_check_constraint_name!(constraint_name)

          unless check_constraint_exists?(table, constraint_name)
            raise missing_schema_object_message(table, "check constraint", constraint_name)
          end

          disable_statement_timeout do
            # VALIDATE CONSTRAINT only requires a SHARE UPDATE EXCLUSIVE LOCK
            # It only conflicts with other validations and creating indexes
            execute("ALTER TABLE #{table} VALIDATE CONSTRAINT #{constraint_name};")
          end
        end

        def remove_check_constraint(table, constraint_name)
          # This is technically not necessary, but aligned with add_check_constraint
          # and allows us to continue use with_lock_retries here
          validate_not_in_transaction!(:remove_check_constraint)

          validate_check_constraint_name!(constraint_name)

          # DROP CONSTRAINT requires an EXCLUSIVE lock
          # Use with_lock_retries to make sure that this will not timeout
          with_lock_retries do
            execute <<-SQL
            ALTER TABLE #{table}
            DROP CONSTRAINT IF EXISTS #{constraint_name}
            SQL
          end
        end

        # Copies all check constraints for the old column to the new column.
        #
        # table - The table containing the columns.
        # old - The old column.
        # new - The new column.
        # schema - The schema the table is defined for
        #          If it is not provided, then the current_schema is used
        def copy_check_constraints(table, old, new, schema: nil)
          raise 'copy_check_constraints can not be run inside a transaction' if transaction_open?

          raise "Column #{old} does not exist on #{table}" unless column_exists?(table, old)

          raise "Column #{new} does not exist on #{table}" unless column_exists?(table, new)

          table_with_schema = schema.present? ? "#{schema}.#{table}" : table

          check_constraints_for(table, old, schema: schema).each do |check_c|
            validate = !(check_c["constraint_def"].end_with? "NOT VALID")

            # Normalize:
            # - Old constraint definitions:
            #    '(char_length(entity_path) <= 5500)'
            # - Definitionss from pg_get_constraintdef(oid):
            #    'CHECK ((char_length(entity_path) <= 5500))'
            # - Definitions from pg_get_constraintdef(oid, pretty_bool):
            #    'CHECK (char_length(entity_path) <= 5500)'
            # - Not valid constraints: 'CHECK (...) NOT VALID'
            # to a single format that we can use:
            #    '(char_length(entity_path) <= 5500)'
            check_definition = check_c["constraint_def"]
                                .sub(/^\s*(CHECK)?\s*\({0,2}/, '(')
                                .sub(/\){0,2}\s*(NOT VALID)?\s*$/, ')')

            constraint_name = if check_definition == "(#{old} IS NOT NULL)"
                                not_null_constraint_name(table_with_schema, new)
                              elsif check_definition.start_with? "(char_length(#{old}) <="
                                text_limit_name(table_with_schema, new)
                              else
                                check_constraint_name(table_with_schema, new, 'copy_check_constraint')
                              end

            add_check_constraint(
              table_with_schema,
              check_definition.gsub(old.to_s, new.to_s),
              constraint_name,
              validate: validate
            )
          end
        end

        # Migration Helpers for adding limit to text columns
        def add_text_limit(table, column, limit, constraint_name: nil, validate: true)
          add_check_constraint(
            table,
            "char_length(#{column}) <= #{limit}",
            text_limit_name(table, column, name: constraint_name),
            validate: validate
          )
        end

        def validate_text_limit(table, column, constraint_name: nil)
          validate_check_constraint(table, text_limit_name(table, column, name: constraint_name))
        end

        def remove_text_limit(table, column, constraint_name: nil)
          remove_check_constraint(table, text_limit_name(table, column, name: constraint_name))
        end

        def check_text_limit_exists?(table, column, constraint_name: nil)
          check_constraint_exists?(table, text_limit_name(table, column, name: constraint_name))
        end

        # Migration Helpers for managing not null constraints
        def add_not_null_constraint(table, column, constraint_name: nil, validate: true)
          if column_is_nullable?(table, column)
            add_check_constraint(
              table,
              "#{column} IS NOT NULL",
              not_null_constraint_name(table, column, name: constraint_name),
              validate: validate
            )
          else
            warning_message = <<~MESSAGE
              NOT NULL check constraint was not created:
              column #{table}.#{column} is already defined as `NOT NULL`
            MESSAGE

            Gitlab::AppLogger.warn warning_message
          end
        end

        def validate_not_null_constraint(table, column, constraint_name: nil)
          validate_check_constraint(
            table,
            not_null_constraint_name(table, column, name: constraint_name)
          )
        end

        def remove_not_null_constraint(table, column, constraint_name: nil)
          remove_check_constraint(
            table,
            not_null_constraint_name(table, column, name: constraint_name)
          )
        end

        def check_not_null_constraint_exists?(table, column, constraint_name: nil)
          check_constraint_exists?(
            table,
            not_null_constraint_name(table, column, name: constraint_name)
          )
        end

        def add_multi_column_not_null_constraint(
          table, *columns, limit: 1, operator: '=', constraint_name: nil, validate: true)

          raise 'Expected multiple columns, use add_not_null_constraint for a single column' unless columns.size > 1

          add_check_constraint(
            table,
            "num_nonnulls(#{columns.sort.join(', ')}) #{operator} #{limit}",
            multi_column_not_null_constraint_name(table, columns, name: constraint_name),
            validate: validate
          )
        end

        def validate_multi_column_not_null_constraint(table, *columns, constraint_name: nil)
          validate_check_constraint(
            table,
            multi_column_not_null_constraint_name(table, columns, name: constraint_name)
          )
        end

        def remove_multi_column_not_null_constraint(table, *columns, constraint_name: nil)
          remove_check_constraint(table, multi_column_not_null_constraint_name(table, columns, name: constraint_name))
        end

        def rename_constraint(table_name, old_name, new_name)
          execute <<~SQL
            ALTER TABLE #{quote_table_name(table_name)}
            RENAME CONSTRAINT #{quote_column_name(old_name)} TO #{quote_column_name(new_name)}
          SQL
        end

        def drop_constraint(table_name, constraint_name, cascade: false)
          execute <<~SQL
            ALTER TABLE #{quote_table_name(table_name)} DROP CONSTRAINT #{quote_column_name(constraint_name)} #{cascade_statement(cascade)}
          SQL
        end

        def switch_constraint_names(table_name, constraint_a, constraint_b)
          validate_not_in_transaction!(:switch_constraint_names)

          with_lock_retries do
            rename_constraint(table_name, constraint_a, :temp_name_for_renaming)
            rename_constraint(table_name, constraint_b, constraint_a)
            rename_constraint(table_name, :temp_name_for_renaming, constraint_b)
          end
        end

        def validate_check_constraint_name!(constraint_name)
          return unless constraint_name.to_s.length > MAX_IDENTIFIER_NAME_LENGTH

          raise "The maximum allowed constraint name is #{MAX_IDENTIFIER_NAME_LENGTH} characters"
        end

        def text_limit_name(table, column, name: nil)
          name.presence || check_constraint_name(table, column, 'max_length')
        end

        private

        def validate_not_in_transaction!(method_name, modifier = nil)
          return unless transaction_open?

          raise <<~ERROR
            #{["`#{method_name}`", modifier].compact.join(' ')} cannot be run inside a transaction.

            You can disable transactions by calling `disable_ddl_transaction!` in the body of
            your migration class
          ERROR
        end

        # Returns an ActiveRecord::Result containing the check constraints
        # defined for the given column.
        #
        # If the schema is not provided, then the current_schema is used
        def check_constraints_for(table, column, schema: nil)
          check_sql = <<~SQL
            SELECT
              ccu.table_schema as schema_name,
              ccu.table_name as table_name,
              ccu.column_name as column_name,
              con.conname as constraint_name,
              pg_get_constraintdef(con.oid) as constraint_def
            FROM pg_catalog.pg_constraint con
              INNER JOIN pg_catalog.pg_class rel
                ON rel.oid = con.conrelid
              INNER JOIN pg_catalog.pg_namespace nsp
                ON nsp.oid = con.connamespace
              INNER JOIN information_schema.constraint_column_usage ccu
                ON con.conname = ccu.constraint_name
                      AND nsp.nspname = ccu.constraint_schema
                      AND rel.relname = ccu.table_name
            WHERE  nsp.nspname = #{connection.quote(schema.presence || current_schema)}
              AND rel.relname = #{connection.quote(table)}
              AND ccu.column_name = #{connection.quote(column)}
              AND con.contype = 'c'
            ORDER BY constraint_name
          SQL

          connection.exec_query(check_sql)
        end

        def cascade_statement(cascade)
          cascade ? 'CASCADE' : ''
        end

        def not_null_constraint_name(table, column, name: nil)
          name.presence || check_constraint_name(table, column, 'not_null')
        end

        def multi_column_not_null_constraint_name(table, columns, name: nil)
          name.presence || check_constraint_name(table, columns.sort.join('_'), 'num_nonnulls')
        end

        def missing_schema_object_message(table, type, name)
          <<~MESSAGE
            Could not find #{type} "#{name}" on table "#{table}" which was referenced during the migration.
            This issue could be caused by the database schema straying from the expected state.

            To resolve this issue, please verify:
              1. all previous migrations have completed
              2. the database objects used in this migration match the Rails definition in schema.rb or structure.sql

          MESSAGE
        end
      end
    end
  end
end
