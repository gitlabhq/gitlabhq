# frozen_string_literal: true

module Authn
  module IamService
    class HttpClient
      RequestError = Class.new(StandardError)

      TIMEOUT_SECONDS = 5

      def put(path:, query_params: {}, body: {})
        request(path: path, query_params: query_params) do |url, options|
          Gitlab::HTTP.put(url, body: body.to_json, **options)
        end
      end

      def get(path:, query_params: {})
        request(path: path, query_params: query_params) do |url, options|
          Gitlab::HTTP.get(url, **options)
        end
      end

      private

      def request(path:, query_params: {})
        url = build_url(path: path, query_params: query_params)
        options = { headers: iam_headers, timeout: TIMEOUT_SECONDS }
        yield(url, options)
      rescue Authn::IamAuthService::ConfigurationError => e
        raise RequestError, e.message
      rescue *Gitlab::HTTP_V2::HTTP_ERRORS => e
        Gitlab::ErrorTracking.track_exception(e)
        raise RequestError, 'Failed to connect to IAM service'
      end

      def build_url(path:, query_params: {})
        uri = URI.parse(Authn::IamAuthService.url)
        uri.path = path
        uri.query = query_params.any? ? URI.encode_www_form(query_params) : nil
        uri.to_s
      end

      def iam_headers
        {
          'Content-Type' => 'application/json',
          Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER => Authn::IamAuthService.secret
        }
      end
    end
  end
end
