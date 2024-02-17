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
    InvalidFieldValueError = Class.new(StandardError)
    ResponseInvalidSizeError = Class.new(StandardError)

    RESPONSE_SIZE_LIMIT = 1.megabyte
    private_constant :RESPONSE_SIZE_LIMIT

    # The bytes size of a JSON payload is different from what DeepSize
    # calculates which is Ruby's object size.
    #
    # This factor accounts for the difference.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/393029#note_1289914133
    RESPONSE_MEMORY_SIZE_LIMIT = RESPONSE_SIZE_LIMIT * 5

    attr_accessor :url, :token

    def initialize(api_url, token)
      @url = api_url
      @token = token
    end

    private

    def validate_size(response)
      bytesize = response.body.bytesize

      if bytesize > RESPONSE_SIZE_LIMIT
        limit = ActiveSupport::NumberHelper.number_to_human_size(RESPONSE_SIZE_LIMIT)
        message = "Sentry API response is too big. Limit is #{limit}. Got #{bytesize} bytes."
        raise ResponseInvalidSizeError, message
      end

      parsed = response.parsed_response
      return if Gitlab::Utils::DeepSize.new(parsed, max_size: RESPONSE_MEMORY_SIZE_LIMIT).valid?

      limit = ActiveSupport::NumberHelper.number_to_human_size(RESPONSE_MEMORY_SIZE_LIMIT)
      message = "Sentry API response memory footprint is too big. Limit is #{limit}."
      raise ResponseInvalidSizeError, message
    end

    def api_urls
      @api_urls ||= SentryClient::ApiUrls.new(@url)
    end

    def handle_mapping_exceptions
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

    def http_request(&block)
      response = handle_request_exceptions(&block)

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
      raise_error "Sentry response status code: #{response.code}" unless response.code.between?(200, 204)

      validate_size(response)

      { body: response.parsed_response, headers: response.headers }
    end

    def raise_error(message)
      raise SentryClient::Error, message
    end

    def ensure_numeric!(field, value)
      return value if /\A\d+\z/.match?(value)

      raise_invalid_field_value!(field, "#{value.inspect} is not numeric")
    end

    def raise_invalid_field_value!(field, message)
      raise InvalidFieldValueError, %(Sentry API response contains invalid value for field "#{field}": #{message})
    end
  end
end
