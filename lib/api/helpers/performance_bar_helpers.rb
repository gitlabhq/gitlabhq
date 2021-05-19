# frozen_string_literal: true

module API
  module Helpers
    module PerformanceBarHelpers
      def set_peek_enabled_for_current_request
        Gitlab::SafeRequestStore.fetch(:peek_enabled) { perf_bar_cookie_enabled? && perf_bar_allowed_for_user? }
      end

      def perf_bar_cookie_enabled?
        cookies[:perf_bar_enabled] == 'true'
      end

      def perf_bar_allowed_for_user?
        # We cannot use `current_user` here because that method raises an exception when the user
        # is unauthorized and some API endpoints require that `current_user` is not called.
        Gitlab::PerformanceBar.allowed_for_user?(find_user_from_sources)
      end
    end
  end
end
