if defined?(GrapeRouteHelpers)
  module GrapeRouteHelpers
    module AllRoutes
      # Bringing in PR https://github.com/reprah/grape-route-helpers/pull/21 due to abandonment.
      #
      # Without the following fix, when two helper methods are the same, but have different arguments
      # (for example: api_v1_cats_owners_path(id: 1) vs api_v1_cats_owners_path(id: 1, owner_id: 2))
      # if the helper method with the least number of arguments is defined first (because the route was defined first)
      # then it will shadow the longer route.
      #
      # The fix is to sort descending by amount of arguments
      def decorated_routes
        @decorated_routes ||= all_routes
                                .map { |r| DecoratedRoute.new(r) }
                                .sort_by { |r| -r.dynamic_path_segments.count }
      end
    end

    class DecoratedRoute
      # GrapeRouteHelpers gem tries to parse the versions
      # from a string, not supporting Grape `version` array definition.
      #
      # Without the following fix, we get this on route helpers generation:
      #
      # => undefined method `scan' for ["v3", "v4"]
      #
      # 2.0.0 implementation of this method:
      #
      # ```
      # def route_versions
      #   version_pattern = /[^\[",\]\s]+/
      #   if route_version
      #     route_version.scan(version_pattern)
      #   else
      #     [nil]
      #   end
      # end
      # ```
      def route_versions
        return [nil] if route_version.nil? || route_version.empty?

        if route_version.is_a?(String)
          version_pattern = /[^\[",\]\s]+/
          route_version.scan(version_pattern)
        else
          route_version
        end
      end
    end
  end
end
