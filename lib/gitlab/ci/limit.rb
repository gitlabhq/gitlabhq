# frozen_string_literal: true

module Gitlab
  module Ci
    ##
    # Abstract base class for CI/CD Quotas
    #
    class Limit
      LimitExceededError = Class.new(StandardError)

      def initialize(_context, _resource); end

      def enabled?
        raise NotImplementedError
      end

      def exceeded?
        raise NotImplementedError
      end

      def message
        raise NotImplementedError
      end

      def log_error!(extra_context = {})
        ::Gitlab::ErrorTracking.log_exception(limit_exceeded_error, extra_context)
      end

      protected

      def limit_exceeded_error
        LimitExceededError.new(message)
      end
    end
  end
end
