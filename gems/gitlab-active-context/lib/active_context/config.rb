# frozen_string_literal: true

module ActiveContext
  class Config
    CONFIG = Struct.new(:enabled, :databases, :logger)

    class << self
      def configure(&block)
        @instance = new(block)
      end

      def config
        @instance&.config || {}
      end

      def enabled?
        config.enabled || false
      end

      def databases
        config.databases || {}
      end

      def logger
        config.logger || Logger.new($stdout)
      end
    end

    def initialize(config_block)
      @config_block = config_block
    end

    def config
      struct = CONFIG.new
      @config_block.call(struct)
      struct
    end
  end
end
