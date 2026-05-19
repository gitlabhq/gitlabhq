# frozen_string_literal: true

module Gitlab
  module Tracking
    # This class replaces SnowplowTracker::AsyncEmitter with a custom implementation
    # that sends events asynchronously using Gitlab's sidekiq worker
    class SnowplowJobEmitter < SnowplowTracker::Emitter
      extend ::Gitlab::Utils::Override

      attr_reader :endpoint, :options

      override :initialize
      def initialize(endpoint:, options: {})
        @options = options.except(:on_success, :on_failure).stringify_keys
        @endpoint = endpoint

        super(endpoint: endpoint, options: @options)
      end

      override :flush
      def flush(_async = true)
        loop do
          batch = nil

          @lock.synchronize do
            # Extract up to buffer_size events from the buffer
            batch = @buffer.slice!(0, @buffer_size)
          end

          break if batch.empty?

          enqueue_worker(batch)
        end
      end

      private

      def enqueue_worker(batch)
        if ApplicationRecord.inside_transaction?
          ApplicationRecord.connection.current_transaction.after_commit do
            ::Analytics::SnowplowEmitterWorker.perform_async(batch, endpoint, options)
          end
        else
          ::Analytics::SnowplowEmitterWorker.perform_async(batch, endpoint, options)
        end
      end
    end
  end
end
