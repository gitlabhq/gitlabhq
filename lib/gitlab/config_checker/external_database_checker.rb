# frozen_string_literal: true

module Gitlab
  module ConfigChecker
    module ExternalDatabaseChecker
      extend self

      def check
        notices = []

        unless Gitlab::Database.postgresql_minimum_supported_version?
          notices <<
            {
              type: 'warning',
              message: _('You are using PostgreSQL %{pg_version_current}, but PostgreSQL ' \
                         '%{pg_version_minimum} is required for this version of GitLab. ' \
                         'Please upgrade your environment to a supported PostgreSQL version, ' \
                         'see %{pg_requirements_url} for details.') % {
                                                                        pg_version_current: Gitlab::Database.version,
                                                                        pg_version_minimum: Gitlab::Database::MINIMUM_POSTGRES_VERSION,
                                                                        pg_requirements_url: '<a href="https://docs.gitlab.com/ee/install/requirements.html#database">database requirements</a>'
                                                                      }
            }
        end

        if Gitlab::Database.postgresql_upcoming_deprecation?
          upcoming_deprecation = Gitlab::Database::UPCOMING_POSTGRES_VERSION_DETAILS

          notices <<
            {
              type: 'warning',
              message: _('Note that PostgreSQL %{pg_version_upcoming} will become the minimum required ' \
                         'version in GitLab %{gl_version_upcoming} (%{gl_version_upcoming_date}). Please ' \
                         'consider upgrading your environment to a supported PostgreSQL version soon, ' \
                         'see <a href="%{pg_version_upcoming_url}">the related epic</a> for details.') % {
                                                                                                           pg_version_upcoming: upcoming_deprecation[:pg_version_minimum],
                                                                                                           gl_version_upcoming: upcoming_deprecation[:gl_version],
                                                                                                           gl_version_upcoming_date: upcoming_deprecation[:gl_version_date],
                                                                                                           pg_version_upcoming_url: upcoming_deprecation[:url]
                                                                                                         }
            }
        end

        notices
      end
    end
  end
end
