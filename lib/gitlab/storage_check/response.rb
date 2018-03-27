require 'json'

module Gitlab
  module StorageCheck
    class Response
      attr_reader :http_response

      def initialize(http_response)
        @http_response = http_response
      end

      def valid?
        @http_response && (200...299).cover?(@http_response.status) &&
          @http_response.headers['Content-Type'].include?('application/json') &&
          parsed_response
      end

      def check_interval
        return nil unless parsed_response

        parsed_response['check_interval']
      end

      def responsive_shards
        divided_results[:responsive_shards]
      end

      def skipped_shards
        divided_results[:skipped_shards]
      end

      def failing_shards
        divided_results[:failing_shards]
      end

      private

      def results
        return [] unless parsed_response

        parsed_response['results']
      end

      def divided_results
        return @divided_results if @divided_results

        @divided_results = {}
        @divided_results[:responsive_shards] = []
        @divided_results[:skipped_shards] = []
        @divided_results[:failing_shards] = []

        results.each do |info|
          name = info['storage']

          case info['success']
          when true
            @divided_results[:responsive_shards] << name
          when false
            @divided_results[:failing_shards] << name
          else
            @divided_results[:skipped_shards] << name
          end
        end

        @divided_results
      end

      def parsed_response
        return @parsed_response if defined?(@parsed_response)

        @parsed_response = JSON.parse(@http_response.body)
      rescue JSON::JSONError
        @parsed_response = nil
      end
    end
  end
end
