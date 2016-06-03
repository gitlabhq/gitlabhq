module Gitlab
  module Ci
    class Config
      class ParserError < StandardError; end

      def initialize(config)
        parser = Parser.new(config)

        unless parser.valid?
          raise ParserError, 'Invalid configuration format!'
        end

        @config = parser.parse
      end

      def to_hash
        @config
      end
    end
  end
end
