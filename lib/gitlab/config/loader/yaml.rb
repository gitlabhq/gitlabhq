# frozen_string_literal: true

module Gitlab
  module Config
    module Loader
      class Yaml
        def initialize(config)
          @config = YAML.safe_load(config, [Symbol], [], true)
        rescue Psych::Exception => e
          raise Loader::FormatError, e.message
        end

        def valid?
          @config.is_a?(Hash)
        end

        def load!
          unless valid?
            raise Loader::FormatError, 'Invalid configuration format'
          end

          @config.deep_symbolize_keys
        end
      end
    end
  end
end
