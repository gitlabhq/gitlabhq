# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module ForeignKeyHelpers
        include TimeoutHelpers
        include LockRetriesHelpers
        include Gitlab::Database::PartitionHelpers

        # Adds a foreign key with only minimal locking on the tables involved.
        #
        # This method only requires minimal locking
        #
        # source - The source table containing the foreign key.
        # target - The target table the key points to.
        # column - The name of the column to create the foreign key on.
        # target_column - The name of the referenced column, defaults to "id".
        # on_delete - The action to perform when associated data is removed,
        #             defaults to "CASCADE".
        # on_update - The action to perform when associated data is updated,
        #             defaults to nil. This is useful for multi column FKs if
        #             it's desirable to update one of the columns.
        # name - The name of the foreign key.
        # validate - Flag that controls whether the new foreign key will be validated after creation.
        #            If the flag is not set, the constraint will only be enforced for new data.
        # reverse_lock_order - Flag that controls whether we should attempt to acquire locks in the reverse
        #                      order of the ALTER TABLE. This can be useful in situations where the foreign
        #                      key creation could deadlock with another process.
        #
        def add_concurrent_foreign_key(source, target, column:, **options)
          options.reverse_merge!({
            on_delete: :cascade,
            on_update: nil,
            target_column: :id,
            validate: true,
            reverse_lock_order: false,
            allow_partitioned: false,
            column: column
          })

          # Transactions would result in ALTER TABLE locks being held for the
          # duration of the transaction, defeating the purpose of this method.
          raise 'add_concurrent_foreign_key can not be run inside a transaction' if transaction_open?

          if !options.delete(:allow_partitioned) && table_partitioned?(source)
            raise ArgumentError, 'add_concurrent_foreign_key can not be used on a partitioned ' \
              'table. Please use add_concurrent_partitioned_foreign_key on the partitioned table ' \
              'as we need to create foreign keys on each partition and a FK on the parent table'
          end

          options[:name] ||= concurrent_foreign_key_name(source, column)
          options[:primary_key] = options[:target_column]
          check_options = options.slice(:column, :on_delete, :on_update, :name, :primary_key)

          if foreign_key_exists?(source, target, **check_options)
            warning_message = "Foreign key not created because it exists already " \
              "(this may be due to an aborted migration or similar): " \
              "source: #{source}, target: #{target}, column: #{options[:column]}, " \
              "name: #{options[:name]}, on_update: #{options[:on_update]}, " \
              "on_delete: #{options[:on_delete]}"

            Gitlab::AppLogger.warn warning_message
          else
            execute_add_concurrent_foreign_key(source, target, options)
          end

          # Validate the existing constraint. This can potentially take a very
          # long time to complete, but fortunately does not lock the source table
          # while running.
          # Disable this check by passing `validate: false` to the method call
          # The check will be enforced for new data (inserts) coming in,
          # but validating existing data is delayed.
          #
          # Note this is a no-op in case the constraint is VALID already

          return unless options[:validate]

          begin
            disable_statement_timeout do
              execute("ALTER TABLE #{source} VALIDATE CONSTRAINT #{options[:name]};")
            end
          rescue PG::ForeignKeyViolation => e
            with_lock_retries do
              execute("ALTER TABLE #{source} DROP CONSTRAINT #{options[:name]};")
            end
            raise "Migration failed intentionally due to ForeignKeyViolation: #{e.message}"
          end
        end

        def validate_foreign_key(source, column, name: nil)
          fk_name = name || concurrent_foreign_key_name(source, column)

          unless foreign_key_exists?(source, name: fk_name)
            raise missing_schema_object_message(source, "foreign key", fk_name)
          end

          disable_statement_timeout do
            execute("ALTER TABLE #{source} VALIDATE CONSTRAINT #{fk_name};")
          end
        end

        def foreign_key_exists?(source, target = nil, **options)
          fks = Gitlab::Database::PostgresForeignKey.by_constrained_table_name_or_identifier(source)
          fks = fks.by_referenced_table_name(target) if target
          fks = fks.by_name(options[:name]) if options[:name]
          fks = fks.by_constrained_columns(options[:column]) if options[:column]
          fks = fks.by_referenced_columns(options[:primary_key]) if options[:primary_key]
          fks = fks.by_on_delete_action(options[:on_delete]) if options[:on_delete]

          fks.exists?
        end

        def remove_foreign_key_if_exists(source, target = nil, **kwargs)
          reverse_lock_order = kwargs.delete(:reverse_lock_order)
          return unless foreign_key_exists?(source, target, **kwargs)

          if target && reverse_lock_order && transaction_open?
            execute("LOCK TABLE #{target}, #{source} IN ACCESS EXCLUSIVE MODE")
          end

          if target
            remove_foreign_key(source, target, **kwargs)
          else
            remove_foreign_key(source, **kwargs)
          end
        end

        def remove_foreign_key_without_error(*args, **kwargs)
          remove_foreign_key(*args, **kwargs)
        rescue ArgumentError
        end

        # Returns the name for a concurrent foreign key.
        #
        # PostgreSQL constraint names have a limit of 63 bytes. The logic used
        # here is based on Rails' foreign_key_name() method, which unfortunately
        # is private so we can't rely on it directly.
        #
        # prefix:
        # - The default prefix is `fk_` for backward compatibility with the existing
        # concurrent foreign key helpers.
        # - For standard rails foreign keys the prefix is `fk_rails_`
        #
        def concurrent_foreign_key_name(table, column, prefix: 'fk_')
          identifier = "#{table}_#{multiple_columns(column, separator: '_')}_fk"
          hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)

          "#{prefix}#{hashed_identifier}"
        end

        private

        def multiple_columns(columns, separator: ', ')
          Array.wrap(columns).join(separator)
        end

        def on_update_statement(on_update)
          return '' if on_update.blank?
          return 'ON UPDATE SET NULL' if on_update == :nullify

          "ON UPDATE #{on_update.upcase}"
        end

        def on_delete_statement(on_delete)
          return '' if on_delete.blank?
          return 'ON DELETE SET NULL' if on_delete == :nullify

          "ON DELETE #{on_delete.upcase}"
        end

        def execute_add_concurrent_foreign_key(source, target, options)
          # Using NOT VALID allows us to create a key without immediately
          # validating it. This means we keep the ALTER TABLE lock only for a
          # short period of time. The key _is_ enforced for any newly created
          # data.
          not_valid = 'NOT VALID'
          lock_mode = 'SHARE ROW EXCLUSIVE'

          if table_partitioned?(source)
            not_valid = ''
            lock_mode = 'ACCESS EXCLUSIVE'
          end

          with_lock_retries do
            execute("LOCK TABLE #{target}, #{source} IN #{lock_mode} MODE") if options[:reverse_lock_order]
            execute(<<~SQL.squish)
              ALTER TABLE #{source}
              ADD CONSTRAINT #{options[:name]}
              FOREIGN KEY (#{multiple_columns(options[:column])})
              REFERENCES #{target} (#{multiple_columns(options[:target_column])})
              #{on_update_statement(options[:on_update])}
              #{on_delete_statement(options[:on_delete])}
              #{not_valid};
            SQL
          end
        end
      end
    end
  end
end
