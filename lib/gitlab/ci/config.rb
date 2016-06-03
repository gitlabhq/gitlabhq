module Gitlab
  module Ci
    class Config
      class ParserError < StandardError; end

      def initialize(config)
        @config = YAML.safe_load(config, [Symbol], [], true)

        unless @config.is_a?(Hash)
          raise ParserError, 'YAML should be a hash'
        end

        @config = @config.deep_symbolize_keys
      end

      def to_hash
        @config
      end
    end
  end
end
