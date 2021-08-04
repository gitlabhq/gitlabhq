# frozen_string_literal: true

require 'rest-client'

module QA
  module Support
    module Api
      HTTP_STATUS_OK = 200
      HTTP_STATUS_CREATED = 201
      HTTP_STATUS_NO_CONTENT = 204
      HTTP_STATUS_ACCEPTED = 202
      HTTP_STATUS_NOT_FOUND = 404
      HTTP_STATUS_SERVER_ERROR = 500

      def post(url, payload, args = {})
        default_args = {
          method: :post,
          url: url,
          payload: payload,
          verify_ssl: false
        }

        RestClient::Request.execute(
          default_args.merge(args)
        )
      rescue RestClient::ExceptionWithResponse => e
        return_response_or_raise(e)
      end

      def get(url, args = {})
        default_args = {
          method: :get,
          url: url,
          verify_ssl: false
        }

        RestClient::Request.execute(
          default_args.merge(args)
        )
      rescue RestClient::ExceptionWithResponse => e
        return_response_or_raise(e)
      end

      def put(url, payload = nil)
        RestClient::Request.execute(
          method: :put,
          url: url,
          payload: payload,
          verify_ssl: false)
      rescue RestClient::ExceptionWithResponse => e
        return_response_or_raise(e)
      end

      def delete(url)
        RestClient::Request.execute(
          method: :delete,
          url: url,
          verify_ssl: false)
      rescue RestClient::ExceptionWithResponse => e
        return_response_or_raise(e)
      end

      def head(url)
        RestClient::Request.execute(
          method: :head,
          url: url,
          verify_ssl: false)
      rescue RestClient::ExceptionWithResponse => e
        return_response_or_raise(e)
      end

      def parse_body(response)
        JSON.parse(response.body, symbolize_names: true)
      end

      def return_response_or_raise(error)
        raise error unless error.respond_to?(:response) && error.response

        error.response
      end

      def auto_paginated_response(url, attempts: 0)
        pages = []
        with_paginated_response_body(url, attempts: attempts) { |response| pages << response }

        pages.flatten
      end

      def with_paginated_response_body(url, attempts: 0)
        not_ok_error = lambda do |resp|
          raise "Failed to GET #{QA::Runtime::API::Request.masked_url(url)} - (#{resp.code}): `#{resp}`."
        end

        loop do
          response = if attempts > 0
                       Retrier.retry_on_exception(max_attempts: attempts, log: false) do
                         get(url).tap { |resp| not_ok_error.call(resp) if resp.code != HTTP_STATUS_OK }
                       end
                     else
                       get(url).tap { |resp| not_ok_error.call(resp) if resp.code != HTTP_STATUS_OK }
                     end

          page, pages = response.headers.values_at(:x_page, :x_total_pages)
          api_endpoint = url.match(%r{v4/(\S+)\?})[1]

          QA::Runtime::Logger.debug("Fetching page (#{page}/#{pages}) for '#{api_endpoint}' ...") unless pages.to_i <= 1

          yield parse_body(response)

          next_link = pagination_links(response).find { |link| link[:rel] == 'next' }
          break unless next_link

          url = next_link[:url]
        end
      end

      def pagination_links(response)
        link = response.headers[:link]
        return unless link

        link.split(',').map do |link|
          match = link.match(/<(?<url>.*)>; rel="(?<rel>\w+)"/)
          break nil unless match

          { url: match[:url], rel: match[:rel] }
        end.compact
      end
    end
  end
end
