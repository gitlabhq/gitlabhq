# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class PathConverter
        # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#paths-object
        def self.convert(routes)
          new(routes).convert
        end

        def initialize(routes)
          @routes = routes
          @config = Gitlab::GrapeOpenapi.configuration
        end

        def convert
          grouped_routes.transform_values do |routes_for_path|
            build_path_item(routes_for_path)
          end
        end

        private

        attr_reader :config, :routes

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
            operation = OperationConverter.convert(route)
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
