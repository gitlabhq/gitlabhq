if defined?(GrapeRouteHelpers)
  module GrapeRouteHelpers
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
