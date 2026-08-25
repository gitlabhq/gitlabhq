# frozen_string_literal: true

module Gitlab
  module Database
    module Capture
      # Single source of truth for the capture feature flag. The query
      # analyzer and the adapter RETURNING patch must use the identical
      # invocation so they share Flipper's per-request memoization and
      # cannot disagree within one request.
      def self.enabled?
        ::Feature.enabled?(:database_capture, ::Feature.current_pod, type: :ops)
      rescue PG::UndefinedTable
        # The feature_gates table does not exist yet (e.g. during migrations)
        false
      end
    end
  end
end
