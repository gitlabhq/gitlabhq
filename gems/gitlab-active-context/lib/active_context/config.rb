# frozen_string_literal: true

module ActiveContext
  class Config
    Cfg = Struct.new(:enabled, :databases, :logger)

    class << self
      def configure(&block)
        @instance = new(block)
      end

      def current
        @instance&.config || Cfg.new
      end

      def enabled?
        current.enabled || false
      end

      def databases
        current.databases || {}
      end

      def logger
        current.logger || Logger.new($stdout)
      end
    end

    def initialize(config_block)
      @config_block = config_block
    end

    def config
      struct = Cfg.new
      @config_block.call(struct)
      struct
    end
  end
end
