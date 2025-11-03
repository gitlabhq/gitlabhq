# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class PathConverter
        def self.convert(routes, schema_registry)
          new(routes, schema_registry).convert
        end

        def initialize(routes, schema_registry)
          @routes = routes
          @schema_registry = schema_registry
          @config = Gitlab::GrapeOpenapi.configuration
        end

        def convert
          grouped_routes.transform_values do |routes_for_path|
            build_path_item(routes_for_path)
          end
        end

        private

        attr_reader :config, :routes, :schema_registry

        def grouped_routes
          routes.group_by { |route| normalize_path(route) }
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
            operation = OperationConverter.convert(route, schema_registry)
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
