# frozen_string_literal: true

module Gitlab
  module CorrelationId
    LOG_KEY = 'correlation_id'.freeze

    class << self
      def use_id(correlation_id, &blk)
        # always generate a id if null is passed
        correlation_id ||= new_id

        ids.push(correlation_id || new_id)

        begin
          yield(current_id)
        ensure
          ids.pop
        end
      end

      def current_id
        ids.last
      end

      def current_or_new_id
        current_id || new_id
      end

      private

      def ids
        Thread.current[:correlation_id] ||= []
      end

      def new_id
        SecureRandom.uuid
      end
    end
  end
end
