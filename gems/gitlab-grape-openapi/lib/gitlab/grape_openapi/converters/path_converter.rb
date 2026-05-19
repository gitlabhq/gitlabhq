# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class PathConverter
        # Grape stores response-entity declarations under :entity (when declared
        # via `entity:` on the route) and :success (when declared via the `success`
        # DSL inside a `desc` block, in any of its forms). EntityConverter.register
        # handles all three shapes (Class, Hash with :model, Array of those).
        RESPONSE_DECLARATIONS = %i[entity success].freeze

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
          groups = {}

          routes.each do |route|
            next if skip_route?(route)

            register_route_entities(route)

            key = grouping_key(route)
            groups[key] ||= []
            groups[key] << route
          end

          groups.transform_keys { |key| normalize_path(groups[key].first) }
        end

        # Register entities declared on the route's response so they appear in
        # `components.schemas` only for routes that are actually emitted.
        # Running this after `skip_route?` keeps registration in sync with the
        # final spec and avoids `no-unused-components` orphans for entities
        # that belong only to hidden routes or wildcard catch-alls.
        def register_route_entities(route)
          RESPONSE_DECLARATIONS.each do |key|
            definition = route.options[key]
            next unless definition

            EntityConverter.register(definition, @schema_registry)
          end
        end

        def skip_route?(route)
          method = extract_method(route)
          path = normalize_path(route)

          # Hidden routes (declared with `hidden true`) must be skipped before
          # OperationConverter runs. Otherwise it pollutes the shared schema and
          # request-body registries with entries that no emitted operation references,
          # surfacing as `no-unused-components` warnings under `components.schemas`.
          return true if hidden?(route)

          # Grape registers catch-all routes with HTTP method * (matches any method) and
          # paths containing *path (wildcard segments). Neither is valid OpenAPI: * isn't
          # an HTTP method, and *path isn't a valid path segment. These are internal
          # Grape routing artifacts, not actual API endpoints.
          method == '*' || path.include?('*')
        end

        def hidden?(route)
          !!route.options.dig(:settings, :description, :hidden)
        end

        def normalize_path(route)
          path = route.pattern.origin

          path
            .gsub(/\(\.:format\)$/, '')
            .gsub(/:\w+/) { |match| "{#{match[1..]}}" }
            .gsub('{version}', config.api_version)
        end

        def grouping_key(route)
          normalize_path(route).gsub(/\{[^}]+\}/, '{param}')
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
          route.options[:method]
        end
      end
    end
  end
end
