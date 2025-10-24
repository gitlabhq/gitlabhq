# frozen_string_literal: true

module Mcp
  module Tools
    class ApiTool
      attr_reader :name, :route, :settings, :version

      # Grape types are represented as a string by calling `.to_s` on a type
      # The values are built based on the existing routes:
      # - [String, Integer] is usually a type of an id, which can be represented as a string
      # - Grape::API::Boolean is a boolean
      # - [Integer] is usually an array passed a parameter
      # - [String] represents a comma-separated string
      TYPE_CONVERSIONS = {
        '[String, Integer]' => 'string',
        'Grape::API::Boolean' => 'boolean',
        '[Integer]' => 'array',
        '[String]' => 'string'
      }.freeze

      def initialize(name:, route:)
        @name = name
        @route = route
        @settings = route.app.route_setting(:mcp)
        @version = @settings[:version] || "0.1.0"
      end

      def description
        route.description
      end

      def input_schema
        params = route.params.slice(*settings[:params].map(&:to_s))
        required_fields = params.filter_map do |param, values|
          param if values[:required]
        end

        properties = params.transform_values do |value|
          { type: parse_type(value[:type]), description: value[:desc] }
        end

        {
          type: 'object',
          properties: properties,
          required: required_fields,
          additionalProperties: false
        }
      end

      def execute(request: nil, params: nil)
        args = params[:arguments]&.slice(*settings[:params]) || {}
        request.env[Grape::Env::GRAPE_ROUTING_ARGS].merge!(args)
        request.env[Rack::REQUEST_METHOD] = route.request_method

        status, _, body = route.exec(request.env)
        process_response(status, Array(body)[0])
      end

      private

      def parse_type(type)
        return TYPE_CONVERSIONS[type] if TYPE_CONVERSIONS.key?(type)

        type.downcase
      end

      def process_response(status, body)
        parsed_response = Gitlab::Json.parse(body)
        if status >= 400
          message = parsed_response['error'] || parsed_response['message'] || "HTTP #{status}"
          ::Mcp::Tools::Response.error(message, parsed_response)
        else
          formatted_content = [{ type: 'text', text: body }]
          ::Mcp::Tools::Response.success(formatted_content, parsed_response)
        end
      rescue JSON::ParserError => e
        ::Mcp::Tools::Response.error('Invalid JSON response', { message: e.message })
      end
    end
  end
end
