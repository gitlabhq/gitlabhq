# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class PathConverter
        def self.convert(routes, schema_registry, request_body_registry)
          new(routes, schema_registry, request_body_registry).convert
        end

        def initialize(routes, schema_registry, request_body_registry)
          @routes = routes
          @schema_registry = schema_registry
          @request_body_registry = request_body_registry
          @config = Gitlab::GrapeOpenapi.configuration
        end

        def convert
          paths = grouped_routes.transform_values do |routes_for_path|
            build_path_item(routes_for_path)
          end

          paths.reject { |_path, operations| operations.empty? }
        end

        private

        attr_reader :config, :routes, :schema_registry, :request_body_registry

        def grouped_routes
          routes
            .reject { |route| skip_route?(route) }
            .group_by { |route| normalize_path(route) }
        end

        def skip_route?(route)
          method = extract_method(route)
          path = normalize_path(route)

          # Grape registers catch-all routes with HTTP method * (matches any method) and
          # paths containing *path (wildcard segments). Neither is valid OpenAPI: * isn't
          # an HTTP method, and *path isn't a valid path segment. These are internal
          # Grape routing artifacts, not actual API endpoints.
          method == '*' || path.include?('*')
        end

        def normalize_path(route)
          pattern = route.instance_variable_get(:@pattern)
          path = pattern.instance_variable_get(:@origin)

          path
            .gsub(/\(\.:format\)$/, '')
            .gsub(/:\w+/) { |match| "{#{match[1..]}}" }
            .gsub('{version}', config.api_version)
        end

        def build_path_item(routes_for_path)
          path_item = Models::PathItem.new

          routes_for_path.each do |route|
            operation = OperationConverter.convert(route, schema_registry, request_body_registry)
            method = extract_method(route)
            path_item.add_operation(method, operation)
          end

          path_item.to_h
        end

        def extract_method(route)
          options = route.instance_variable_get(:@options)
          options[:method]
        end
      end
    end
  end
end
