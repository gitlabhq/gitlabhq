# frozen_string_literal: true

module Gitlab
  module ConfigChecker
    module ExternalDatabaseChecker
      extend self

      def check
        return [] if Gitlab::Database.main.postgresql_minimum_supported_version?

        [
          {
            type: 'warning',
            message: _('You are using PostgreSQL %{pg_version_current}, but PostgreSQL ' \
                       '%{pg_version_minimum} is required for this version of GitLab. ' \
                       'Please upgrade your environment to a supported PostgreSQL version, ' \
                       'see %{pg_requirements_url} for details.') % {
                                                                      pg_version_current: Gitlab::Database.main.version,
                                                                      pg_version_minimum: Gitlab::Database::MINIMUM_POSTGRES_VERSION,
                                                                      pg_requirements_url: '<a href="https://docs.gitlab.com/ee/install/requirements.html#database">database requirements</a>'
                                                                    }
          }
        ]
      end
    end
  end
end
