# frozen_string_literal: true

module Routing
  module Groups
    module ObservabilityHelper
      # Unified helper that generates the correct observability URL regardless of
      # whether +path+ is a single-segment string (e.g. "services") or a
      # multi-segment string (e.g. "services/my-service/top-level-operations").
      #
      # Single-segment paths are dispatched to the +:id+ resource route
      # (/groups/*group_id/-/observability/:id).
      # Multi-segment paths are dispatched to the wildcard *sub_path route
      # (/groups/*group_id/-/observability/*sub_path).
      def group_observability_path(group, path, **options)
        if path.to_s.include?('/')
          group_observability_sub_path_path(group, sub_path: path, **options)
        else
          super
        end
      end
    end
  end
end
