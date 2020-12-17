# frozen_string_literal: true

module Gitlab
  module Ci
    ##
    # Abstract base class for CI/CD Quotas
    #
    class Limit
      LimitExceededError = Class.new(StandardError)

      def initialize(_context, _resource)
      end

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
        error = LimitExceededError.new(message)
        # TODO: change this to Gitlab::ErrorTracking.log_exception(error, extra_context)
        # https://gitlab.com/gitlab-org/gitlab/issues/32906
        ::Gitlab::ErrorTracking.track_exception(error, extra_context)
      end
    end
  end
end
