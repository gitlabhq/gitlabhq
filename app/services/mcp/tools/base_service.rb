# frozen_string_literal: true

module Mcp
  module Tools
    class BaseService
      def initialize(name:)
        @name = name
      end

      def set_cred(**)
        raise NoMethodError
      end

      def execute(request: nil, params: nil) # rubocop: disable Lint/UnusedMethodArgument -- request param to match Mcp::Tools::ApiTool
        args = params[:arguments]
        validate_arguments!(args)
        perform(args)
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

      # Tool availability check, returns `true` by default.
      # Tools should override this method if they need to check for specific conditions.
      def available?
        true
      end

      protected

      def perform(_arguments = {}, _query = {})
        raise NoMethodError
      end

      private

      attr_reader :name, :current_user, :access_token

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

      def version
        raise NoMethodError
      end
    end
  end
end
