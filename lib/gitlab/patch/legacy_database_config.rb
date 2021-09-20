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
    module LegacyDatabaseConfig
      extend ActiveSupport::Concern

      prepended do
        attr_reader :uses_legacy_database_config
      end

      def database_configuration
        @uses_legacy_database_config = false # rubocop:disable Gitlab/ModuleWithInstanceVariables

        super.to_h do |env, configs|
          # This check is taken from Rails where the transformation
          # of a flat database.yml is done into `primary:`
          # https://github.com/rails/rails/blob/v6.1.4/activerecord/lib/active_record/database_configurations.rb#L169
          if configs.is_a?(Hash) && !configs.all? { |_, v| v.is_a?(Hash) }
            configs = { "main" => configs }

            @uses_legacy_database_config = true # rubocop:disable Gitlab/ModuleWithInstanceVariables
          end

          [env, configs]
        end
      end
    end
  end
end
