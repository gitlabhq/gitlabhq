# frozen_string_literal: true

module Grafana
  class Client
    Error = Class.new(StandardError)

    # @param api_url [String] Base URL of the Grafana instance
    # @param token [String] Admin-level API token for instance
    def initialize(api_url:, token:)
      @api_url = api_url
      @token = token
    end

    # @param uid [String] Unique identifier for a Grafana dashboard
    def get_dashboard(uid:)
      http_get("#{@api_url}/api/dashboards/uid/#{uid}")
    end

    # @param name [String] Unique identifier for a Grafana datasource
    def get_datasource(name:)
      # CGI#escape formats strings such that the Grafana endpoint
      # will not recognize the dashboard name. Prefer Addressable::URI#encode_component.
      http_get("#{@api_url}/api/datasources/name/#{Addressable::URI.encode_component(name)}")
    end

    # @param datasource_id [String] Grafana ID for the datasource
    # @param proxy_path [String] Path to proxy - ex) 'api/v1/query_range'
    def proxy_datasource(datasource_id:, proxy_path:, query: {})
      http_get("#{@api_url}/api/datasources/proxy/#{datasource_id}/#{proxy_path}", query: query)
    end

    private

    def http_get(url, params = {})
      response = handle_request_exceptions do
        Gitlab::HTTP.get(url, **request_params.merge(params))
      end

      handle_response(response)
    end

    def request_params
      {
        headers: {
          'Authorization' => "Bearer #{@token}",
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        },
        follow_redirects: false
      }
    end

    def handle_request_exceptions
      yield
    rescue Gitlab::HTTP::Error
      raise_error 'Error when connecting to Grafana'
    rescue Net::OpenTimeout
      raise_error 'Connection to Grafana timed out'
    rescue SocketError
      raise_error 'Received SocketError when trying to connect to Grafana'
    rescue OpenSSL::SSL::SSLError
      raise_error 'Grafana returned invalid SSL data'
    rescue Errno::ECONNREFUSED
      raise_error 'Connection refused'
    rescue StandardError => e
      raise_error "Grafana request failed due to #{e.class}"
    end

    def handle_response(response)
      return response if response.code == 200

      raise_error "Grafana response status code: #{response.code}, Message: #{response.body}"
    end

    def raise_error(message)
      raise Client::Error, message
    end
  end
end
