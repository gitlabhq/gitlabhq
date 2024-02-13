# frozen_string_literal: true

# NOTE: DO NOT use this class for loading GitLab CI configuration files.
# Instead, use `Gitlab::Ci::Config::Yaml.load!`, which will properly handle
# CI configuration headers.

module Gitlab
  module Config
    module Loader
      class Yaml
        DataTooLargeError = Class.new(Loader::FormatError)
        NotHashError = Class.new(Loader::FormatError)

        include Gitlab::Utils::StrongMemoize

        attr_reader :raw

        def initialize(config, additional_permitted_classes: [])
          @raw = config
          @config = YAML.safe_load(config,
            permitted_classes: [Symbol, *additional_permitted_classes],
            permitted_symbols: [],
            aliases: true
          )
        rescue Psych::Exception => e
          raise Loader::FormatError, e.message
        end

        def valid?
          hash? && !too_big?
        end

        def load_raw!
          raise DataTooLargeError, 'The parsed YAML is too big' if too_big?
          raise NotHashError, 'Invalid configuration format' unless hash?

          @config
        end

        def load!
          @symbolized_config ||= load_raw!.deep_symbolize_keys
        end

        def blank?
          @config.blank?
        end

        private

        def hash?
          @config.is_a?(Hash)
        end

        def too_big?
          !deep_size.valid?
        end

        def deep_size
          strong_memoize(:deep_size) do
            Gitlab::Utils::DeepSize.new(@config,
              max_size: Gitlab::CurrentSettings.current_application_settings.max_yaml_size_bytes,
              max_depth: Gitlab::CurrentSettings.current_application_settings.max_yaml_depth)
          end
        end
      end
    end
  end
end
