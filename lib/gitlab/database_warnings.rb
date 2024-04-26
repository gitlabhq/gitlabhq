# frozen_string_literal: true

module Gitlab
  module DatabaseWarnings
    def self.check_postgres_version_and_print_warning
      return if Gitlab::Runtime.rails_runner?

      Gitlab::Database.database_base_models.each do |name, model|
        database = Gitlab::Database::Reflection.new(model)

        next if database.postgresql_minimum_supported_version?

        Kernel.warn ERB.new(Rainbow.new.wrap(<<~WARNING).red).result

                    ██     ██  █████  ██████  ███    ██ ██ ███    ██  ██████ 
                    ██     ██ ██   ██ ██   ██ ████   ██ ██ ████   ██ ██      
                    ██  █  ██ ███████ ██████  ██ ██  ██ ██ ██ ██  ██ ██   ███ 
                    ██ ███ ██ ██   ██ ██   ██ ██  ██ ██ ██ ██  ██ ██ ██    ██ 
                     ███ ███  ██   ██ ██   ██ ██   ████ ██ ██   ████  ██████  

          ******************************************************************************
            You are using PostgreSQL #{database.version} for the #{name} database, but this version of GitLab requires PostgreSQL >= <%= Gitlab::Database::MINIMUM_POSTGRES_VERSION %>.
            <% if Rails.env.development? || Rails.env.test? %>
            If using gitlab-development-kit, please find the relevant steps here:
              https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/postgresql.md#upgrade-postgresql
            <% end %>
            Please upgrade your environment to a supported PostgreSQL version. See
            https://docs.gitlab.com/ee/install/requirements.html#database for details.
          ******************************************************************************
        WARNING
      rescue ActiveRecord::ActiveRecordError, PG::Error
        # ignore - happens when Rake tasks yet have to create a database, e.g. for testing
      end
    end

    def self.check_single_connection_and_print_warning
      return if Gitlab::Runtime.rails_runner?
      return unless Gitlab::Database.database_mode == Gitlab::Database::MODE_SINGLE_DATABASE

      Kernel.warn ERB.new(Rainbow.new.wrap(<<~WARNING).red).result

                  ██     ██  █████  ██████  ███    ██ ██ ███    ██  ██████ 
                  ██     ██ ██   ██ ██   ██ ████   ██ ██ ████   ██ ██      
                  ██  █  ██ ███████ ██████  ██ ██  ██ ██ ██ ██  ██ ██   ███ 
                  ██ ███ ██ ██   ██ ██   ██ ██  ██ ██ ██ ██  ██ ██ ██    ██ 
                   ███ ███  ██   ██ ██   ██ ██   ████ ██ ██   ████  ██████  

        ******************************************************************************
          Your database has a single connection, and single connections were
          deprecated in GitLab 15.9 https://docs.gitlab.com/ee/update/deprecations.html#single-database-connection-is-deprecated.

          In GitLab 17.0 and later, you must have the two main: and ci: sections in your database.yml.

          Please add a :ci section to your database, following these instructions:
          https://docs.gitlab.com/ee/install/installation.html#configure-gitlab-db-settings.
        ******************************************************************************
      WARNING
    end
  end
end

Gitlab::DatabaseWarnings.prepend_mod_with('Gitlab::DatabaseWarnings')
