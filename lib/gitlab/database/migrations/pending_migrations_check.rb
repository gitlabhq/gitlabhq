# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      # Checks for pending migrations, excluding post-deployment migrations.
      #
      # Post-deployment migrations are added to the runtime migration path by default
      # (see `Gitlab::Database.add_post_migrate_path_to_rails`), but per our deployment
      # model the running application does not depend on them. Failing on pending
      # post-deployment migrations would report a healthy instance as down during every
      # upgrade. Pending *regular* migrations mean the schema is behind the running code,
      # so those are still reported.
      class PendingMigrationsCheck
        class << self
          # Replicates `ActiveRecord::Migration.check_pending_migrations` but excludes
          # post-deployment migrations. Raises `ActiveRecord::PendingMigrationError` when
          # regular migrations are pending.
          #
          # See https://github.com/rails/rails/blob/v7.2.3.1/activerecord/lib/active_record/migration.rb#L752-L758
          def check!
            migrations = pending_migrations

            raise ActiveRecord::PendingMigrationError.new(pending_migrations: migrations) if migrations.any?
          end

          private

          def pending_migrations
            migrations = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).flat_map do |db_config|
              ActiveRecord::PendingMigrationConnection.with_temporary_pool(db_config) do |pool|
                pool.migration_context.open.pending_migrations
              end
            end

            migrations.reject { |migration| post_deployment_migration?(migration) }
          end

          def post_deployment_migration?(migration)
            migration.filename.to_s.match?(POST_DEPLOYMENT_PATH_REGEX)
          end
        end
      end
    end
  end
end
