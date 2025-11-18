# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#security-scheme-object
      class SecurityScheme
        VALID_TYPES = %w[apiKey http oauth2 openIdConnect].freeze
        VALID_IN_VALUES = %w[query header cookie].freeze
        VALID_HTTP_SCHEMES = %w[basic bearer oauth].freeze

        attr_accessor :type, :description, :name, :in, :scheme, :bearer_format,
          :flows, :open_id_connect_url

        def initialize(type:, **options)
          @type = type
          validate_type!

          @description = options[:description]

          case @type
          when 'apiKey'
            @name = options[:name] || raise(ArgumentError, "name is required for apiKey type")
            @in = options[:in] || raise(ArgumentError, "in is required for apiKey type")
            validate_in!
          when 'http'
            @scheme = options[:scheme] || raise(ArgumentError, "scheme is required for http type")
            validate_http_scheme!
            @bearer_format = options[:bearer_format] if @scheme == 'bearer'
          when 'oauth2'
            @flows = options[:flows] || raise(ArgumentError, "flows is required for oauth2 type")
            validate_oauth2_flows!
          when 'openIdConnect'
            @open_id_connect_url = options[:open_id_connect_url] ||
              raise(ArgumentError, "open_id_connect_url is required for openIdConnect type")
          end
        end

        def to_h
          hash = { 'type' => @type }
          hash['description'] = @description if @description

          case @type
          when 'apiKey'
            hash['name'] = @name
            hash['in'] = @in
          when 'http'
            hash['scheme'] = @scheme
            hash['bearerFormat'] = @bearer_format if @bearer_format
          when 'oauth2'
            hash['flows'] = flows_to_hash(@flows)
          when 'openIdConnect'
            hash['openIdConnectUrl'] = @open_id_connect_url
          end

          hash
        end

        private

        def validate_type!
          return if VALID_TYPES.include?(@type)

          raise ArgumentError, "Invalid type: #{@type}. Must be one of: #{VALID_TYPES.join(', ')}"
        end

        def validate_in!
          return if VALID_IN_VALUES.include?(@in)

          raise ArgumentError, "Invalid 'in' value: #{@in}. Must be one of: #{VALID_IN_VALUES.join(', ')}"
        end

        def validate_http_scheme!
          return if VALID_HTTP_SCHEMES.include?(@scheme.downcase)

          raise ArgumentError, "Invalid HTTP scheme: #{@scheme}. Common values: #{VALID_HTTP_SCHEMES.join(', ')}"
        end

        def validate_oauth2_flows!
          raise ArgumentError, "flows must be a Hash" unless @flows.is_a?(Hash)

          valid_flow_types = %w[implicit password clientCredentials authorizationCode]
          @flows.each do |flow_type, flow_config|
            unless valid_flow_types.include?(flow_type.to_s)
              raise ArgumentError, "Invalid flow type: #{flow_type}. Must be one of: #{valid_flow_types.join(', ')}"
            end

            validate_flow_config!(flow_type.to_s, flow_config)
          end
        end

        # rubocop:disable Metrics/CyclomaticComplexity -- Method is clear and readable
        def validate_flow_config!(flow_type, config)
          raise ArgumentError, "Flow configuration must be a Hash" unless config.is_a?(Hash)

          case flow_type
          when 'implicit'
            raise ArgumentError, "authorizationUrl required for implicit flow" unless config[:authorizationUrl]
            raise ArgumentError, "scopes required for implicit flow" unless config[:scopes]
          when 'password'
            raise ArgumentError, "tokenUrl required for password flow" unless config[:tokenUrl]
            raise ArgumentError, "scopes required for password flow" unless config[:scopes]
          when 'clientCredentials'
            raise ArgumentError, "tokenUrl required for clientCredentials flow" unless config[:tokenUrl]
            raise ArgumentError, "scopes required for clientCredentials flow" unless config[:scopes]
          when 'authorizationCode'
            raise ArgumentError, "authorizationUrl required for authorizationCode flow" unless config[:authorizationUrl]
            raise ArgumentError, "tokenUrl required for authorizationCode flow" unless config[:tokenUrl]
            raise ArgumentError, "scopes required for authorizationCode flow" unless config[:scopes]
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def flows_to_hash(flows)
          result = {}
          flows.each do |flow_type, config|
            flow_hash = {}
            flow_hash['authorizationUrl'] = config[:authorizationUrl] if config[:authorizationUrl]
            flow_hash['tokenUrl'] = config[:tokenUrl] if config[:tokenUrl]
            flow_hash['refreshUrl'] = config[:refreshUrl] if config[:refreshUrl]
            flow_hash['scopes'] = config[:scopes] || {}
            result[flow_type.to_s] = flow_hash
          end
          result
        end
      end
    end
  end
end
