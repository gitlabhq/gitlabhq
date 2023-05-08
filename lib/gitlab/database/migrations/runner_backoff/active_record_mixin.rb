# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module RunnerBackoff
        module ActiveRecordMixin
          module ActiveRecordMigrationProxyRunnerBackoff
            # Regular AR migrations don't have this,
            # only ones inheriting from Gitlab::Database::Migration have
            def enable_runner_backoff?
              !!migration.try(:enable_runner_backoff?)
            end
          end

          module ActiveRecordMigratorRunnerBackoff
            def execute_migration_in_transaction(migration)
              if migration.enable_runner_backoff?
                RunnerBackoff::Communicator.execute_with_lock(migration) { super }
              else
                super
              end
            end
          end

          def self.patch!
            ActiveRecord::MigrationProxy.prepend(ActiveRecordMigrationProxyRunnerBackoff)
            ActiveRecord::Migrator.prepend(ActiveRecordMigratorRunnerBackoff)
          end
        end
      end
    end
  end
end
