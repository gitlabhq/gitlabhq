# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module PgBackendPid
        module MigratorPgBackendPid
          extend ::Gitlab::Utils::Override

          override :with_advisory_lock
          def with_advisory_lock
            Gitlab::Database::Migrations::PgBackendPid.say(connection)

            super
          ensure
            Gitlab::Database::Migrations::PgBackendPid.say(connection)
          end
        end

        def self.patch!
          ActiveRecord::Migrator.prepend(MigratorPgBackendPid)
        end

        def self.say(conn)
          return unless ActiveRecord::Migration.verbose

          pg_backend_pid = conn.select_value('SELECT pg_backend_pid()')
          db_name = Gitlab::Database.db_config_name(conn)

          # rubocop:disable Rails/Output
          puts "#{db_name}: == [advisory_lock_connection] " \
               "object_id: #{conn.object_id}, pg_backend_pid: #{pg_backend_pid}"
          # rubocop:enable Rails/Output
        end
      end
    end
  end
end
