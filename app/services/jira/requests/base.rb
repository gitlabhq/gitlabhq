# frozen_string_literal: true

module Jira
  module Requests
    class Base
      include ProjectServicesLoggable

      JIRA_API_VERSION = 2

      def initialize(jira_integration, params = {})
        @project = jira_integration&.project
        @jira_integration = jira_integration
      end

      def execute
        return ServiceResponse.error(message: _('Jira service not configured.')) unless jira_integration&.active?

        request
      end

      private

      attr_reader :jira_integration, :project

      # We have to add the context_path here because the Jira client is not taking it into account
      def base_api_url
        "#{context_path}/rest/api/#{api_version}"
      end

      def context_path
        client.options[:context_path].to_s
      end

      # override this method in the specific request class implementation if a differnt API version is required
      def api_version
        JIRA_API_VERSION
      end

      def client
        @client ||= jira_integration.client
      end

      def request
        response = client.get(url)
        build_service_response(response)
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, URI::InvalidURIError, JIRA::HTTPError, OpenSSL::SSL::SSLError => error
        error_message = "Jira request error: #{error.message}"
        log_error("Error sending message", client_url: client.options[:site],
                  error: {
                    exception_class: error.class.name,
                    exception_message: error.message,
                    exception_backtrace: Gitlab::BacktraceCleaner.clean_backtrace(error.backtrace)
                  })
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
