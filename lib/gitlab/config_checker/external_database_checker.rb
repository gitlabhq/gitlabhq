# frozen_string_literal: true

module Gitlab
  module ConfigChecker
    module ExternalDatabaseChecker
      extend self

      # DB is considered deprecated if it is below version 11
      def db_version_deprecated?
        Gitlab::Database.version.to_f < 11
      end

      def check
        return [] unless db_version_deprecated?

        [
          {
            type: 'warning',
            message: _('Note that PostgreSQL 11 will become the minimum required PostgreSQL version in GitLab 13.0 (May 2020). '\
                     'PostgreSQL 9.6 and PostgreSQL 10 will no longer be supported in GitLab 13.0. '\
                     'Please consider upgrading your PostgreSQL version (%{db_version}) soon.') % { db_version: Gitlab::Database.version.to_s }
          }
        ]
      end
    end
  end
end
