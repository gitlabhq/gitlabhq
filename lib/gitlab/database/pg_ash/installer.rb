# frozen_string_literal: true

module Gitlab
  module Database
    module PgAsh
      # Applies, removes and inspects the vendored pg_ash install script.
      #
      # Re-applying the same vendored version is a no-op and is safe, but upstream ships a
      # separate migration chain for moving between versions, and that chain is
      # not vendored currently (to be added in future releases).
      # #install therefore refuses to run over a different installed version.
      #
      # Targets the main database only. Support for ci and sec
      # depends on telling co-located databases apart, because pg_stat_activity
      # is cluster-wide: https://gitlab.com/gitlab-org/gitlab/-/issues/608099
      class Installer
        PermissionError = Class.new(StandardError)
        VersionMismatchError = Class.new(StandardError)

        def initialize(connection = ApplicationRecord.connection)
          @connection = connection
        end

        # @return [String] the version now stamped in ash.config
        def install
          current = installed_version
          raise VersionMismatchError, version_mismatch_message(current) if current && current != VENDORED_VERSION

          execute(PgAsh.install_sql)

          installed_version
        rescue ActiveRecord::StatementInvalid => e
          raise unless e.cause.is_a?(PG::InsufficientPrivilege)

          raise PermissionError, permission_denied_message
        end

        # @return [Boolean] false when pg_ash was not installed to begin with
        def uninstall
          return false unless installed?

          execute("SELECT #{PgAsh::SCHEMA_NAME}.uninstall('yes')")

          true
        end

        # @return [Hash, nil] metric => value, or nil when pg_ash is not installed
        def status
          return unless installed?

          execute("SELECT metric, value FROM #{PgAsh::SCHEMA_NAME}.status()")
            .to_h { |row| [row['metric'], row['value']] }
        end

        def installed?
          connection.schema_exists?(PgAsh::SCHEMA_NAME)
        end

        def installed_version
          return unless installed?

          execute("SELECT version FROM #{PgAsh::SCHEMA_NAME}.config WHERE singleton").first&.fetch('version')
        end

        private

        attr_reader :connection

        # The ash schema is absent from the gitlab_schema dictionary, so the
        # analyzers reject any statement that touches it.
        def execute(sql)
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
            Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
              # rubocop:disable Database/AvoidUsingConnectionExecute -- DDL must run on the primary
              connection.execute(sql)
              # rubocop:enable Database/AvoidUsingConnectionExecute
            end
          end
        end

        def version_mismatch_message(current)
          <<~MSG
            pg_ash #{current} is installed, but this GitLab vendors #{VENDORED_VERSION}.

            The vendored script installs pg_ash; it does not upgrade an existing
            install. To move to #{VENDORED_VERSION}, either:

              * run gitlab:db:pg_ash:uninstall first, which drops the
                '#{PgAsh::SCHEMA_NAME}' schema and every sample collected so far, then
                run this task again, or
              * apply the upstream migration chain by hand. See
                https://github.com/NikolayS/pg_ash/tree/main/sql/migrations
          MSG
        end

        def permission_denied_message
          database = ApplicationRecord.database

          <<~MSG
            Installing pg_ash creates the '#{PgAsh::SCHEMA_NAME}' schema in database
            '#{database.database_name}', but user '#{database.username}' is not allowed to create it.

            Grant the privilege using a database superuser:

                GRANT CREATE ON DATABASE #{database.database_name} TO #{database.username};

            Then run this task again. The install script is idempotent, so it is
            safe to re-apply after a failure.
          MSG
        end
      end
    end
  end
end
