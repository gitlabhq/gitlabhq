# frozen_string_literal: true

module QA
  module Support
    module Api
      HTTP_STATUS_OK = 200
      HTTP_STATUS_CREATED = 201

      def post(url, payload)
        RestClient::Request.execute(
          method: :post,
          url: url,
          payload: payload,
          verify_ssl: false)
      rescue RestClient::ExceptionWithResponse => e
        e.response
      end

      def get(url, raw_response: false)
        RestClient::Request.execute(
          method: :get,
          url: url,
          verify_ssl: false,
          raw_response: raw_response)
      rescue RestClient::ExceptionWithResponse => e
        e.response
      end

      def put(url, payload)
        RestClient::Request.execute(
          method: :put,
          url: url,
          payload: payload,
          verify_ssl: false)
      rescue RestClient::ExceptionWithResponse => e
        e.response
      end

      def delete(url)
        RestClient::Request.execute(
          method: :delete,
          url: url,
          verify_ssl: false)
      rescue RestClient::ExceptionWithResponse => e
        e.response
      end

      def head(url)
        RestClient::Request.execute(
          method: :head,
          url: url,
          verify_ssl: false)
      rescue RestClient::ExceptionWithResponse => e
        e.response
      end

      def parse_body(response)
        JSON.parse(response.body, symbolize_names: true)
      end
    end
  end
end
