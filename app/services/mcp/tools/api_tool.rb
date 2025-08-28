# frozen_string_literal: true

module Mcp
  module Tools
    class ApiTool
      attr_reader :route, :settings

      def initialize(route)
        @route = route
        @settings = route.app.route_setting(:mcp)
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

      def execute(request, params)
        args = params[:arguments]&.slice(*settings[:params]) || {}
        request.env[Grape::Env::GRAPE_ROUTING_ARGS].merge!(args)
        request.env[Rack::REQUEST_METHOD] = route.request_method

        status, _, body = route.exec(request.env)
        process_response(status, Array(body)[0])
      end

      private

      def parse_type(type)
        array_str_match = type.match(/^\[(.*)\]$/)
        if array_str_match
          return array_str_match[1].split(", ")[0].downcase # return the first element from [String, Integer] types
        end

        return 'boolean' if type == 'Grape::API::Boolean'
        return 'array' if type.start_with?('Array')

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
