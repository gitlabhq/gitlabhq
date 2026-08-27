# frozen_string_literal: true

module Gitlab
  module Database
    # pg_ash (Active Session History for PostgreSQL)
    module PgAsh
      SCHEMA_NAME = 'ash'

      # Version stamped into ash.config.version by the vendored script. Keep in
      # step with db/pg_ash/README.md when refreshing the vendored copy.
      VENDORED_VERSION = '2.0-beta1'

      INSTALL_SQL_PATH = 'db/pg_ash/sql/ash-install.sql'

      # The vendored script targets psql; its \set meta-commands are not SQL and
      # would fail under connection.execute, so drop them.
      def self.install_sql
        File.read(Rails.root.join(INSTALL_SQL_PATH))
          .gsub(/^\\.*\n/, '')
      end
    end
  end
end
