# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents an array of file paths.
        #
        class Files < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          DEFAULT_MAX_SIZE = 2

          validations do
            validates :config, array_of_strings: true
            validates :config, length: {
              minimum: 1,
              maximum: ->(entry) { entry.max_size },
              too_short: 'requires at least %{count} item',
              too_long: 'has too many items (maximum is %{count})'
            }
          end

          def max_size
            return DEFAULT_MAX_SIZE unless opt(:max_size) && increased_limit_enabled?

            opt(:max_size)
          end

          def value
            config.map do |file_path|
              if file_path.start_with?('/')
                file_path.sub(%r{^/+}, '')
              else
                file_path
              end
            end
          end

          private

          def increased_limit_enabled?
            ::Gitlab::Ci::Config::FeatureFlags.enabled?(:increase_ci_cache_key_files_limit)
          end
        end
      end
    end
  end
end
