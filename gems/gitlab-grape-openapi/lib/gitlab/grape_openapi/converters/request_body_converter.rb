# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class RequestBodyConverter
        DEFAULT_CONTENT_TYPE = 'application/json'
        MULTIPART_FORM_DATA_CONTENT_TYPE = 'multipart/form-data'
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
              content_type(body_params) => {
                schema: schema
              }
            }
          }
        end

        # TODO: not all endpoints use the MULTIPART_FORM_DATA_CONTENT_TYPE or DEFAULT_CONTENT_TYPE
        #   content types. Come up with a way to find which one each endpoint uses, e.g., get it from
        #   the endpoint's docs.
        def content_type(body_params)
          return MULTIPART_FORM_DATA_CONTENT_TYPE if allows_file_upload?(body_params)

          DEFAULT_CONTENT_TYPE
        end

        def allows_file_upload?(body_params)
          body_params.any? do |_key, param_options|
            param_options[:type]&.include?('API::Validations::Types::WorkhorseFile')
          end
        end
      end
    end
  end
end
