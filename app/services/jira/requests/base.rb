# frozen_string_literal: true

module Jira
  module Requests
    class Base
      include ProjectServicesLoggable

      PER_PAGE = 50

      attr_reader :jira_service, :project, :limit, :start_at, :query

      def initialize(jira_service, limit: PER_PAGE, start_at: 0, query: nil)
        @project = jira_service&.project
        @jira_service = jira_service

        @limit    = limit
        @start_at = start_at
        @query    = query
      end

      def execute
        return ServiceResponse.error(message: _('Jira service not configured.')) unless jira_service&.active?
        return ServiceResponse.success(payload: empty_payload) if limit.to_i <= 0

        request
      end

      private

      def client
        @client ||= jira_service.client
      end

      def request
        response = client.get(url)
        build_service_response(response)
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, URI::InvalidURIError, JIRA::HTTPError, OpenSSL::SSL::SSLError => error
        error_message = "Jira request error: #{error.message}"
        log_error("Error sending message", client_url: client.options[:site], error: error_message)
        ServiceResponse.error(message: error_message)
      end

      def url
        raise NotImplementedError
      end

      def build_service_response(response)
        raise NotImplementedError
      end
    end
  end
end
