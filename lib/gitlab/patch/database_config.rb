# frozen_string_literal: true

# The purpose of this code is to transform legacy `database.yml`
# into a `database.yml` containing `main:` as a name of a first database
#
# This should be removed once all places using legacy `database.yml`
# are fixed. The likely moment to remove this check is the %14.0.
#
# This converts the following syntax:
#
# production:
#   adapter: postgresql
#   database: gitlabhq_production
#   username: git
#   password: "secure password"
#   host: localhost
#
# Into:
#
# production:
#   main:
#     adapter: postgresql
#     database: gitlabhq_production
#     username: git
#     password: "secure password"
#     host: localhost
#

module Gitlab
  module Patch
    module DatabaseConfig
      extend ActiveSupport::Concern

      prepended do
        attr_reader :uses_legacy_database_config
      end

      def load_database_yaml
        return super unless Gitlab.ee?

        super.deep_merge(load_geo_database_yaml)
      end

      # This method is taken from Rails to load a database YAML file without
      # evaluating ERB. This allows us to create the rake tasks for the Geo
      # tracking database without filling in the configuration values or
      # loading the environment. To be removed when we start configure Geo
      # tracking database in database.yml instead of custom database_geo.yml
      #
      # https://github.com/rails/rails/blob/v6.1.4/railties/lib/rails/application/configuration.rb#L255
      def load_geo_database_yaml
        path = Rails.root.join("config/database_geo.yml")
        return {} unless File.exist?(path)

        require "rails/application/dummy_erb_compiler"

        yaml = DummyERB.new(Pathname.new(path).read).result
        config = YAML.load(yaml) || {} # rubocop:disable Security/YAMLLoad

        config.to_h do |env, configs|
          # This check is taken from Rails where the transformation
          # of a flat database.yml is done into `primary:`
          # https://github.com/rails/rails/blob/v6.1.4/activerecord/lib/active_record/database_configurations.rb#L169
          if configs.is_a?(Hash) && !configs.all? { |_, v| v.is_a?(Hash) }
            configs = { "geo" => configs }
          end

          [env, configs]
        end
      end

      def database_configuration
        @uses_legacy_database_config = false # rubocop:disable Gitlab/ModuleWithInstanceVariables

        super.to_h do |env, configs|
          # TODO: To be removed in 15.0. See https://gitlab.com/gitlab-org/gitlab/-/issues/338182
          # This preload is needed to convert legacy `database.yml`
          # from `production: adapter: postgresql`
          # into a `production: main: adapter: postgresql`
          unless Gitlab::Utils.to_boolean(ENV['SKIP_DATABASE_CONFIG_VALIDATION'], default: false)
            # This check is taken from Rails where the transformation
            # of a flat database.yml is done into `primary:`
            # https://github.com/rails/rails/blob/v6.1.4/activerecord/lib/active_record/database_configurations.rb#L169
            if configs.is_a?(Hash) && !configs.all? { |_, v| v.is_a?(Hash) }
              configs = { "main" => configs }

              @uses_legacy_database_config = true # rubocop:disable Gitlab/ModuleWithInstanceVariables
            end
          end

          if Gitlab.ee?
            if !configs.key?("geo") && File.exist?(Rails.root.join("config/database_geo.yml"))
              configs["geo"] = Rails.application.config_for(:database_geo).stringify_keys
            end

            if configs.key?("geo")
              migrations_paths = Array(configs["geo"]["migrations_paths"])
              migrations_paths << "ee/db/geo/migrate" if migrations_paths.empty?
              migrations_paths << "ee/db/geo/post_migrate" unless ENV['SKIP_POST_DEPLOYMENT_MIGRATIONS']

              configs["geo"]["migrations_paths"] = migrations_paths.uniq
              configs["geo"]["schema_migrations_path"] = "ee/db/geo/schema_migrations" if configs["geo"]["schema_migrations_path"].blank?
            end
          end

          [env, configs]
        end
      end
    end
  end
end
