# frozen_string_literal: true

module API
  module Helpers
    module Snippets
      # Maps service response reasons to HTTP status codes.
      # See design discussion: https://gitlab.com/gitlab-org/gitlab/-/issues/356036
      class HttpResponseMap
        REASON_TO_HTTP_STATUS = {
          success: 200,
          error: 400,
          invalid_params_error: 422,
          failed_to_create_error: 400,
          failed_to_update_error: 400
        }.freeze

        UNHANDLED = 'Unhandled service reason'

        def self.status_for(reason)
          REASON_TO_HTTP_STATUS[reason] || unhandled_reason_error(reason)
        end

        def self.unhandled_reason_error(reason)
          Gitlab::AppLogger.warn(message: UNHANDLED, reason: reason.inspect)

          500
        end
        private_class_method :unhandled_reason_error
      end
    end
  end
end
