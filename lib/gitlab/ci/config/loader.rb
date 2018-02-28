module Gitlab
  module Ci
    class Config
      class Loader
        FormatError = Class.new(StandardError)

        def initialize(config)
          @config = YAML.safe_load(config, [Symbol], [], true)
        rescue Psych::Exception => e
          raise FormatError, e.message
        end

        def valid?
          @config.is_a?(Hash)
        end

        def load!
          unless valid?
            raise FormatError, 'Invalid configuration format'
          end

          @config.deep_symbolize_keys
        end
      end
    end
  end
end
