# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class RequestBodyConverter
        DEFAULT_CONTENT_TYPE = 'application/json'
        GET_METHOD = 'GET'
        DELETE_METHOD = 'DELETE'

        attr_reader :route, :options, :params

        def self.convert(route:, options:, params:)
          new(route: route, options: options, params: params).convert
        end

        def initialize(route:, options:, params:)
          @route = route
          @options = options
          @params = params
        end

        def convert
          return nil if route_method == GET_METHOD || route_method == DELETE_METHOD
          return nil if params.empty?

          body_params = Models::RequestBody::Parameters.new(route: route, params: params).extract
          return nil if body_params.empty?

          build_request_body(body_params)
        end

        private

        def route_method
          options[:method]
        end

        def build_request_body(body_params)
          properties = {}
          required_params = []
          parameter_schema = Models::RequestBody::ParameterSchema.new(route: route)

          body_params.each do |key, param_options|
            schema = parameter_schema.build(key, param_options)
            properties[key.to_s] = schema
            required_params << key.to_s if param_options[:required]
          end

          schema = {
            type: 'object',
            properties: properties
          }
          schema[:required] = required_params unless required_params.empty?

          {
            required: required_params.any?,
            content: {
              DEFAULT_CONTENT_TYPE => {
                schema: schema
              }
            }
          }
        end
      end
    end
  end
end
