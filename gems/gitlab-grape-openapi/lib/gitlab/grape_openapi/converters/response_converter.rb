# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class ResponseConverter
        def initialize(route, schema_registry)
          @route = route
          @schema_registry = schema_registry
          @responses = {}
        end

        def convert
          extract_success_response
          extract_failure_responses
          add_default_if_empty
          @responses
        end

        private

        def extract_success_response
          entity_definition = @route.options[:entity]
          return unless entity_definition

          case entity_definition
          when Class
            process_class_entity(entity_definition)
          when Hash
            process_hash_entity(entity_definition)
          when Array
            process_array_entities(entity_definition)
          end
        end

        def process_class_entity(entity_class)
          if grape_entity?(entity_class)
            add_response_with_entity(
              status_code: infer_success_code,
              description: http_status_text(infer_success_code),
              entity_class: entity_class
            )
          else
            add_simple_response(
              status_code: infer_success_code,
              description: http_status_text(infer_success_code)
            )
          end
        end

        def process_hash_entity(entity_hash)
          if entity_hash[:model] && grape_entity?(entity_hash[:model])
            add_response_with_entity(
              status_code: entity_hash[:code] || infer_success_code,
              description: http_status_text(entity_hash[:code] || infer_success_code),
              entity_class: entity_hash[:model]
            )
          else
            add_simple_response(
              status_code: entity_hash[:code] || infer_success_code,
              description: http_status_text(entity_hash[:code] || infer_success_code)
            )
          end
        end

        def process_array_entities(entity_array)
          entity_array.each do |definition|
            case definition
            when Hash
              process_array_hash_item(definition)
            when Class
              process_class_entity(definition)
            end
          end
        end

        def process_array_hash_item(definition)
          if definition[:model] && grape_entity?(definition[:model])
            add_response_with_entity(
              status_code: definition[:code] || infer_success_code,
              description: definition[:message] || http_status_text(definition[:code] || infer_success_code),
              entity_class: definition[:model]
            )
          else
            add_simple_response(
              status_code: definition[:code] || infer_success_code,
              description: definition[:message] || http_status_text(definition[:code] || infer_success_code)
            )
          end
        end

        def extract_failure_responses
          http_codes = @route.http_codes || []

          http_codes.each do |failure_def|
            case failure_def
            when Hash
              add_simple_response(
                status_code: failure_def[:code],
                description: failure_def[:message]
              )
            when Array
              add_simple_response(
                status_code: failure_def[0],
                description: failure_def[1]
              )
            end
          end
        end

        def add_response_with_entity(status_code:, description:, entity_class:)
          response = Models::Response.new(
            status_code: status_code,
            description: description,
            entity_class: entity_class
          )

          @responses[response.status_code] = response.to_h(@schema_registry)
        end

        def add_simple_response(status_code:, description:)
          @responses[status_code.to_s] = { description: description }
        end

        def add_default_if_empty
          return if @responses.any?

          code = infer_success_code
          add_simple_response(
            status_code: code,
            description: http_status_text(code)
          )
        end

        def infer_success_code
          case http_method
          when 'POST' then 201
          when 'DELETE' then 204
          else 200
          end
        end

        def http_status_text(code)
          Rack::Utils::HTTP_STATUS_CODES[code.to_i] || 'Success'
        end

        def http_method
          @route.instance_variable_get(:@options)[:method]
        end

        def grape_entity?(klass)
          klass.is_a?(Class) && klass.ancestors.include?(Grape::Entity)
        end
      end
    end
  end
end
