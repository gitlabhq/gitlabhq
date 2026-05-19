# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module TriggerHelpers
        # Installs triggers in a table that keep a new column in sync with an old
        # one.
        #
        # table - The name of the table to install the trigger in.
        # old_column - The name of the old column.
        # new_column - The name of the new column.
        # trigger_name - The name of the trigger to use (optional).
        def install_rename_triggers(table, old, new, trigger_name: nil)
          Gitlab::Database::UnidirectionalCopyTrigger.on_table(table, connection: connection).create(old, new,
            trigger_name: trigger_name)
        end

        # Removes the triggers used for renaming a column concurrently.
        def remove_rename_triggers(table, trigger)
          Gitlab::Database::UnidirectionalCopyTrigger.on_table(table, connection: connection).drop(trigger)
        end

        # Returns the (base) name to use for triggers when renaming columns.
        def rename_trigger_name(table, old, new)
          Gitlab::Database::UnidirectionalCopyTrigger.on_table(table, connection: connection).name(old, new)
        end

        # Installs a trigger in a table that assigns a sharding key from an associated table.
        #
        # table: The table to install the trigger in.
        # sharding_key: The column to be assigned on `table`.
        # parent_table: The associated table with the sharding key to be copied.
        # parent_sharding_key: The sharding key on the parent table that will be copied to `sharding_key` on `table`.
        # foreign_key: The column used to fetch the relevant record from `parent_table`.
        def install_sharding_key_assignment_trigger(**args)
          Gitlab::Database::Triggers::AssignDesiredShardingKey.new(**args.merge(connection: connection)).create
        end

        # Removes trigger used for assigning sharding keys.
        #
        # table: The table to install the trigger in.
        # sharding_key: The column to be assigned on `table`.
        # parent_table: The associated table with the sharding key to be copied.
        # parent_sharding_key: The sharding key on the parent table that will be copied to `sharding_key` on `table`.
        # foreign_key: The column used to fetch the relevant record from `parent_table`.
        def remove_sharding_key_assignment_trigger(**args)
          Gitlab::Database::Triggers::AssignDesiredShardingKey.new(**args.merge(connection: connection)).drop
        end

        def check_trigger_permissions!(table)
          return if Grant.create_and_execute_trigger?(table)

          dbname = ApplicationRecord.database.database_name
          user = ApplicationRecord.database.username

          raise <<~MESSAGE
              Your database user is not allowed to create, drop, or execute triggers on the
              table #{table}.

              If you are using PostgreSQL you can solve this by logging in to the GitLab
              database (#{dbname}) using a super user and running:

                  ALTER #{user} WITH SUPERUSER

              This query will grant the user super user permissions, ensuring you don't run
              into similar problems in the future (e.g. when new tables are created).
          MESSAGE
        end
      end
    end
  end
end
