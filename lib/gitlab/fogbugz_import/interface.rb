# frozen_string_literal: true

module Gitlab
  module FogbugzImport
    class Interface
      RequestError = Class.new(StandardError)
      InitializationError = Class.new(StandardError)
      AuthenticationError = Class.new(StandardError)

      attr_accessor :options, :http, :xml, :token

      def initialize(options = {})
        @options = {}.merge(options)
        raise InitializationError, 'Must supply URI (e.g. https://fogbugz.company.com)' unless options[:uri]

        @token = options[:token] if options[:token]
        # Custom adapter to validate the URL before each request
        # This way we avoid DNS rebinds or other unsafe requests
        @http = HttpAdapter.new(uri: options[:uri], ca_file: options[:ca_file])
        # Custom adapter to validate size of incoming XML before
        # attempting to parse it.
        @xml = XmlAdapter
      end

      def authenticate
        response = @http.request(
          :logon,
          params: {
            email: @options[:email],
            password: @options[:password]
          })

        parsed_response = @xml.parse(response)
        @token ||= parsed_response['token']
        raise AuthenticationError, parsed_response['error'] if @token.blank?

        @token
      end

      def command(action, parameters = {})
        raise RequestError, 'No token available, #authenticate first' unless @token

        parameters[:token] = @token

        response = @http.request action, params: parameters.merge(options[:params] || {})

        @xml.parse(response)
      end
    end
  end
end
