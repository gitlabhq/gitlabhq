# frozen_string_literal: true

module Gitlab
  module ConfigChecker
    module ExternalDatabaseChecker
      extend self

      PG_REQUIREMENTS_LINK =
        '<a href="https://docs.gitlab.com/ee/install/requirements.html#database">database requirements</a>'

      def check
        unsupported_database = Gitlab::Database
          .database_base_models
          .map { |_, model| Gitlab::Database::Reflection.new(model) }
          .reject(&:postgresql_minimum_supported_version?)

        unsupported_database.map do |database|
          {
            type: 'warning',
            message: _('You are using PostgreSQL %{pg_version_current}, but PostgreSQL ' \
                       '%{pg_version_minimum} is required for this version of GitLab. ' \
                       'Please upgrade your environment to a supported PostgreSQL version, ' \
                       'see %{pg_requirements_url} for details.') % \
              {
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
