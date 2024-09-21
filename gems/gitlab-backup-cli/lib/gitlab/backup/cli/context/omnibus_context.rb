# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Context
        class OmnibusContext < SourceContext
          OMNIBUS_CONFIG_ENV = 'GITLAB_BACKUP_CLI_CONFIG_FILE'

          # Is the tool running in an Omnibus installation?
          #
          # @return [Boolean]
          def self.available?
            ENV.key?(OMNIBUS_CONFIG_ENV) && omnibus_config_filepath.exist?
          end

          # @return [Pathname|Nillable]
          def self.omnibus_config_filepath
            unless ENV.key?(OMNIBUS_CONFIG_ENV)
              raise ::Gitlab::Backup::Cli::Error, "#{OMNIBUS_CONFIG_ENV} is not defined"
            end

            Pathname(ENV.fetch(OMNIBUS_CONFIG_ENV))
          end

          private

          def omnibus_config
            return @omnibus_config if defined?(@omnibus_config)

            @omnibus_config ||= OmnibusConfig.new(self.class.omnibus_config_filepath).then do |config|
              raise ::Gitlab::Backup::Cli::Error, 'Failed to load Omnibus environment file' unless config.loaded?

              config
            end
          end

          def build_gitlab_config
            Gitlab::Backup::Cli::GitlabConfig.new(omnibus_config.dig(:gitlab, :config_path))
          end
        end
      end
    end
  end
end
