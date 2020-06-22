# frozen_string_literal: true

module Jira
  module Requests
    class Base
      include ProjectServicesLoggable

      attr_reader :jira_service, :project, :query

      def initialize(jira_service, query: nil)
        @project = jira_service&.project
        @jira_service = jira_service
        @query = query
      end

      def execute
        return ServiceResponse.error(message: _('Jira service not configured.')) unless jira_service&.active?

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
