# frozen_string_literal: true

module ActiveContext
  class Config
    QueueClassError = Class.new(StandardError)

    Cfg = Struct.new(
      :enabled,
      :logger,
      :indexing_enabled,
      :re_enqueue_indexing_workers,
      :migrations_path,
      :connection_model,
      :collection_model,
      :queue_classes
    )

    class << self
      def configure(&block)
        @instance = new(block)

        validate_queue_classes
      end

      def current
        @instance&.config || Cfg.new
      end

      def enabled?
        current.enabled || false
      end

      def migrations_path
        current.migrations_path || Rails.root.join('ee/db/active_context/migrate')
      end

      def connection_model
        current.connection_model || ::Ai::ActiveContext::Connection
      end

      def collection_model
        current.collection_model || ::Ai::ActiveContext::Collection
      end

      def logger
        current.logger || ::Logger.new($stdout)
      end

      def indexing_enabled?
        return false unless enabled?

        current.indexing_enabled || false
      end

      def re_enqueue_indexing_workers?
        current.re_enqueue_indexing_workers || false
      end

      def queue_classes
        current.queue_classes || []
      end

      private

      def validate_queue_classes
        return if @instance.config.queue_classes.nil?

        raise QueueClassError, "`queue_classes` must be an array" unless @instance.config.queue_classes.is_a?(Array)

        all_valid_queues = @instance.config.queue_classes.all? do |q|
          q.include?(ActiveContext::Concerns::Queue)
        end

        raise QueueClassError, "`queue_classes` must include `ActiveContext::Concerns::Queue`" unless all_valid_queues
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
