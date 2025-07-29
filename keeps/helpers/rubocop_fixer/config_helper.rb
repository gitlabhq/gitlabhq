# frozen_string_literal: true

module Keeps
  module Helpers
    module RubocopFixer
      # Manages Rubocop configuration checks
      class ConfigHelper
        GITLAB_RUBOCOP_CONFIG_FILE_PATH = '.rubocop.yml'

        def can_autocorrect?(rule)
          autocorrect_supported?(rule) && safe_autocorrect_supported?(rule)
        end

        private

        def autocorrect_supported?(rule)
          config_key_enabled?(rule, 'AutoCorrect')
        end

        def safe_autocorrect_supported?(rule)
          config_key_enabled?(rule, 'SafeAutoCorrect')
        end

        def config_key_enabled?(rule, key)
          # Can be nil in which case we can autocorrect therefore, explicit comparison to false
          default_rubocop_config.for_cop(rule)[key] != false &&
            gitlab_rubocop_config.for_cop(rule)[key] != false
        end

        def gitlab_rubocop_config
          @gitlab_rubocop_config ||= ::RuboCop::ConfigLoader.load_file(GITLAB_RUBOCOP_CONFIG_FILE_PATH)
        end

        def default_rubocop_config
          @default_rubocop_config ||= ::RuboCop::ConfigLoader.default_configuration
        end
      end
    end
  end
end
