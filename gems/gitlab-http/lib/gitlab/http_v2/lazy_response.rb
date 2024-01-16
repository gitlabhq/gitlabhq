# frozen_string_literal: true

module Gitlab
  module HTTP_V2
    class LazyResponse
      NotExecutedError = Class.new(StandardError)

      attr_reader :promise

      delegate :state, :complete?, to: :promise

      def initialize(promise, path, options, log_info)
        @promise = promise
        @path = path
        @options = options
        @log_info = log_info
      end

      def execute
        @promise.execute
        self
      end

      def wait
        @promise.wait
        self
      end

      def value
        raise NotExecutedError, '`execute` must be called before `value`' if @promise.unscheduled?

        wait # wait for the promise to be completed

        raise @promise.reason if @promise.rejected?

        @promise.value
      rescue HTTParty::RedirectionTooDeep
        raise HTTP_V2::RedirectionTooDeep
      rescue *HTTP_V2::HTTP_ERRORS => e
        extra_info = @log_info || {}
        extra_info = @log_info.call(e, @path, @options) if @log_info.respond_to?(:call)
        Gitlab::HTTP_V2.configuration.log_exception(e, extra_info)

        raise e
      end
    end
  end
end
