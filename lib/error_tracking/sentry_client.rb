# frozen_string_literal: true

module ErrorTracking
  class SentryClient
    include SentryClient::Event
    include SentryClient::Projects
    include SentryClient::Issue
    include SentryClient::Repo
    include SentryClient::IssueLink

    Error = Class.new(StandardError)
    MissingKeysError = Class.new(StandardError)

    attr_accessor :url, :token

    def initialize(api_url, token)
      @url = api_url
      @token = token
    end

    private

    def api_urls
      @api_urls ||= SentryClient::ApiUrls.new(@url)
    end

    def handle_mapping_exceptions(&block)
      yield
    rescue KeyError => e
      Gitlab::ErrorTracking.track_exception(e)
      raise MissingKeysError, "Sentry API response is missing keys. #{e.message}"
    end

    def request_params
      {
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@token}"
        },
        follow_redirects: false
      }
    end

    def http_get(url, params = {})
      http_request do
        Gitlab::HTTP.get(url, **request_params.merge(params))
      end
    end

    def http_put(url, params = {})
      http_request do
        Gitlab::HTTP.put(url, **request_params.merge(body: params.to_json))
      end
    end

    def http_post(url, params = {})
      http_request do
        Gitlab::HTTP.post(url, **request_params.merge(body: params.to_json))
      end
    end

    def http_request
      response = handle_request_exceptions do
        yield
      end

      handle_response(response)
    end

    def handle_request_exceptions
      yield
    rescue Gitlab::HTTP::Error => e
      Gitlab::ErrorTracking.track_exception(e)
      raise_error 'Error when connecting to Sentry'
    rescue Net::OpenTimeout
      raise_error 'Connection to Sentry timed out'
    rescue SocketError
      raise_error 'Received SocketError when trying to connect to Sentry'
    rescue OpenSSL::SSL::SSLError
      raise_error 'Sentry returned invalid SSL data'
    rescue Errno::ECONNREFUSED
      raise_error 'Connection refused'
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
      raise_error "Sentry request failed due to #{e.class}"
    end

    def handle_response(response)
      unless response.code.between?(200, 204)
        raise_error "Sentry response status code: #{response.code}"
      end

      { body: response.parsed_response, headers: response.headers }
    end

    def raise_error(message)
      raise SentryClient::Error, message
    end
  end
end
