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
          @responses
        end

        private

        def extract_success_response
          entity_definition = @route.options[:entity] || @route.options[:success]

          case entity_definition
          when nil
            success_code = infer_success_code
            add_simple_response(
              status_code: success_code,
              description: http_status_text(success_code)
            )
          when Class
            process_class_entity(entity_definition)
          when Hash
            process_hash_entity(entity_definition)
          when Array
            process_array_entities(entity_definition)
          end
        end

        def process_class_entity(entity_class)
          success_code = infer_success_code
          if EntityConverter.grape_entity?(entity_class)
            add_response_with_entity(
              status_code: success_code,
              description: http_status_text(success_code),
              entity_class: entity_class
            )
          else
            add_simple_response(
              status_code: success_code,
              description: http_status_text(success_code)
            )
          end
        end

        def process_hash_entity(entity_hash)
          success_code = infer_success_code

          if entity_hash[:model] && EntityConverter.grape_entity?(entity_hash[:model])
            add_response_with_entity(
              status_code: entity_hash[:code] || success_code,
              description: http_status_text(entity_hash[:code] || success_code),
              entity_class: entity_hash[:model],
              example: entity_hash[:example],
              examples: entity_hash[:examples]
            )
          else
            add_simple_response(
              status_code: entity_hash[:code] || success_code,
              description: http_status_text(entity_hash[:code] || success_code)
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
          if definition[:model] && EntityConverter.grape_entity?(definition[:model])
            add_response_with_entity(
              status_code: definition[:code] || infer_success_code,
              description: definition[:message] || http_status_text(definition[:code] || infer_success_code),
              entity_class: definition[:model],
              example: definition[:example],
              examples: definition[:examples]
            )
          else
            add_simple_response(
              status_code: definition[:code] || infer_success_code,
              description: definition[:message] || http_status_text(definition[:code] || infer_success_code)
            )
          end
        end

        def extract_failure_responses
          http_codes = @route.http_codes.presence || infer_failure_codes

          http_codes.each do |failure_def|
            case failure_def
            when Hash
              add_simple_response(
                status_code: failure_def[:code],
                description: failure_def[:message] || http_status_text(failure_def[:code])
              )
            when Array
              add_simple_response(
                status_code: failure_def[0],
                description: failure_def[1] || http_status_text(failure_def[0])
              )
            end
          end
        end

        def add_response_with_entity(status_code:, description:, entity_class:, example: nil, examples: nil)
          response = Models::Response.new(
            status_code: status_code,
            description: description,
            entity_class: entity_class,
            example: example,
            examples: examples
          )

          @responses[response.status_code] = response.to_h(@schema_registry)
        end

        def add_simple_response(status_code:, description:)
          key = status_code.to_s

          # `http_codes` (processed by `extract_failure_responses`) may include
          # success codes that are also covered by a `success`/`entity`
          # declaration. Preserve the existing response content (the entity
          # `$ref`) and only refresh the description, so the entity is not
          # silently dropped.
          if @responses[key]
            @responses[key][:description] = description
          else
            @responses[key] = { description: description }
          end
        end

        def infer_success_code
          case http_method
          when 'POST' then 201
          when 'DELETE' then 204
          else 200
          end
        end

        def infer_failure_codes
          codes = []
          codes << 404 if path_has_resource_parameters?
          codes << 400 if route_params.any? || %w[POST PUT PATCH].include?(http_method)
          codes.map { |code| { code: code, message: http_status_text(code) } }
        end

        def route_params
          @route.options[:params] || {}
        end

        def path_has_resource_parameters?
          path = @route.path
            .gsub('.:format', '')
            .gsub(':version', '')
          path.include?(':')
        end

        def http_status_text(code)
          Rack::Utils::HTTP_STATUS_CODES[code.to_i] || 'Success'
        end

        def http_method
          @route.options[:method]
        end
      end
    end
  end
end
