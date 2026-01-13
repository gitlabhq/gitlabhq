# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      module RequestBody
        class Parameters
          attr_reader :route, :params

          def initialize(route:, params:)
            @route = route
            @params = params
          end

          def extract
            body_params = params.reject do |key, _|
              path_with_params.include?("{#{key}}")
            end

            restructure_nested_params(body_params)
          end

          private

          def path_with_params
            @path_with_params ||= begin
              pattern = route.instance_variable_get(:@pattern)
              path = pattern.instance_variable_get(:@origin)
              path
                .gsub(/\(\.:format\)$/, '')
                .gsub(/:\w+/) { |match| "{#{match[1..]}}" }
            end
          end

          def restructure_nested_params(body_params)
            # Separate root params from nested params (with bracket notation)
            root_params = {}
            nested_map = {}

            body_params.each do |key, param_options|
              key_str = key.to_s
              if key_str.include?('[')
                # Parse bracket notation like "assets[links][name]"
                parts = parse_bracket_notation(key_str)
                nested_map[parts] = param_options
              else
                root_params[key] = param_options
              end
            end

            # Build nested structure
            nested_map.each do |parts, param_options|
              insert_nested_param(root_params, parts, param_options)
            end

            root_params
          end

          def parse_bracket_notation(key)
            key.scan(/\w+/)
          end

          def insert_nested_param(root_params, parts, param_options)
            return if parts.empty?

            first = parts[0]
            rest = parts[1..]

            # Ensure the root param exists as a Hash/object
            root_params[first] ||= { type: 'Hash', required: false }

            if rest.empty?
              # This is a direct property (e.g., just "config")
              # Merge param_options to preserve description and other metadata
              root_params[first] = root_params[first].merge(param_options)
            elsif rest.length == 1
              # This is the parent of the final property (e.g., "assets[links]")
              root_params[first][:params] ||= {}
              root_params[first][:params][rest[0]] = param_options
            else
              # Multiple levels remaining - recurse to handle arbitrary depth
              # (e.g., "config[database][pool][max_connections]")
              root_params[first][:params] ||= {}
              insert_nested_param(root_params[first][:params], rest, param_options)
            end
          end
        end
      end
    end
  end
end
