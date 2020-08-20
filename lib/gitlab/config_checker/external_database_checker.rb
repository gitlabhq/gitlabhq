# frozen_string_literal: true

module Gitlab
  module ConfigChecker
    module ExternalDatabaseChecker
      extend self

      def check
        notices = []

        unless Gitlab::Database.postgresql_minimum_supported_version?
          string_args = {
            pg_version_current: Gitlab::Database.version,
            pg_version_minimum: Gitlab::Database::MINIMUM_POSTGRES_VERSION,
            pg_requirements_url_open: '<a href="https://docs.gitlab.com/ee/install/requirements.html#database">'.html_safe,
            pg_requirements_url_close: '</a>'.html_safe
          }

          notices <<
            {
              type: 'warning',
              message: html_escape(_('You are using PostgreSQL %{pg_version_current}, but PostgreSQL ' \
                         '%{pg_version_minimum} is required for this version of GitLab. ' \
                         'Please upgrade your environment to a supported PostgreSQL version, ' \
                         'see %{pg_requirements_url_open}database requirements%{pg_requirements_url_close} for details.')) % string_args
            }
        end

        if Gitlab::Database.postgresql_upcoming_deprecation? && Gitlab::Database.within_deprecation_notice_window?
          upcoming_deprecation = Gitlab::Database::UPCOMING_POSTGRES_VERSION_DETAILS

          string_args = {
            pg_version_upcoming: upcoming_deprecation[:pg_version_minimum],
            gl_version_upcoming: upcoming_deprecation[:gl_version],
            gl_version_upcoming_date: upcoming_deprecation[:gl_version_date],
            pg_version_upcoming_url_open: "<a href=\"#{upcoming_deprecation[:url]}\">".html_safe,
            pg_version_upcoming_url_close: '</a>'.html_safe
          }

          notices <<
            {
              type: 'warning',
              message: html_escape(_('Note that PostgreSQL %{pg_version_upcoming} will become the minimum required ' \
                         'version in GitLab %{gl_version_upcoming} (%{gl_version_upcoming_date}). Please ' \
                         'consider upgrading your environment to a supported PostgreSQL version soon, ' \
                         'see %{pg_version_upcoming_url_open}the related epic%{pg_version_upcoming_url_close} for details.')) % string_args
            }
        end

        notices
      end
    end
  end
end
