# frozen_string_literal: true

module Mcp
  module Tools
    class BaseService
      def initialize(name:)
        @name = name
      end

      def execute(access_token, arguments = {})
        validate_arguments!(arguments)
        perform(access_token, arguments)
      rescue ArgumentError => e
        Response.error("Validation error: #{e.message}")
      rescue StandardError => e
        Response.error("Tool execution failed: #{e.message}")
      end

      def to_h
        {
          name: name,
          description: description,
          inputSchema: input_schema
        }
      end

      protected

      def perform(_access_token, _arguments, _query)
        raise NoMethodError
      end

      private

      attr_reader :name

      def validate_arguments!(arguments)
        schemer = JSONSchemer.schema(input_schema)
        json_arguments = arguments ? arguments.deep_stringify_keys : {}
        errors = schemer.validate(json_arguments).to_a

        return if errors.empty?

        validations = errors.map do |error|
          if error['type'] == 'required'
            "#{error['details']['missing_keys'].first} is missing"
          else
            field = error['data_pointer'].sub(%r{^/}, '')
            "#{field} is invalid"
          end
        end.uniq

        raise ArgumentError, validations.join(', ')
      end

      def input_schema_pagination_params
        {
          per_page: {
            type: 'integer',
            description: 'Number of items to list per page. (default: 20)',
            minimum: 1
          },
          page: {
            type: 'integer',
            description: 'Page number to retrieve. (default: 1)',
            minimum: 1
          }
        }
      end

      def description
        raise NoMethodError
      end

      def input_schema
        raise NoMethodError
      end
    end
  end
end
