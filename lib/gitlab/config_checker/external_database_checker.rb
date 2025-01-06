# frozen_string_literal: true

module Gitlab
  module ConfigChecker
    module ExternalDatabaseChecker
      extend self

      PG_REQUIREMENTS_LINK =
        '<a href="https://docs.gitlab.com/ee/install/requirements.html#database">database requirements</a>'

      def check
        unsupported_databases = Gitlab::Database
          .database_base_models
          .each_with_object({}) do |(database_name, base_model), databases|
            database = Gitlab::Database::Reflection.new(base_model)

            databases[database_name] = database unless database.postgresql_minimum_supported_version?
          end

        unsupported_databases.map do |database_name, database|
          {
            type: 'warning',
            message: _(
              'Database \'%{database_name}\' is using PostgreSQL %{pg_version_current}, ' \
              'but this version of GitLab requires PostgreSQL %{pg_version_minimum}. ' \
              'Please upgrade your environment to a supported PostgreSQL version. ' \
              'See %{pg_requirements_url} for details.'
            ) % {
              database_name: database_name,
              pg_version_current: database.version,
              pg_version_minimum: Gitlab::Database::MINIMUM_POSTGRES_VERSION,
              pg_requirements_url: PG_REQUIREMENTS_LINK
            }
          }
        end
      end
    end
  end
end
