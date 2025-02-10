# frozen_string_literal: true

module Jira
  module Requests
    class Base
      include SafeFormatHelper

      JIRA_API_VERSION = 2
      # Limit the size of the JSON error message we will attempt to parse, as the JSON is external input.
      JIRA_ERROR_JSON_SIZE_LIMIT = 5_000

      ERRORS = {
        connection: [Errno::ECONNRESET, Errno::ECONNREFUSED],
        jira_ruby: JIRA::HTTPError,
        ssl: OpenSSL::SSL::SSLError,
        timeout: [Timeout::Error, Errno::ETIMEDOUT],
        uri: [URI::InvalidURIError, SocketError],
        url_blocked: Gitlab::HTTP::BlockedUrlError
      }.freeze
      ALL_ERRORS = ERRORS.values.flatten.freeze

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
      rescue *ALL_ERRORS => error
        jira_integration.log_exception(error,
          message: 'Error sending message',
          client_url: client.options[:site]
        )

        ServiceResponse.error(message: error_message(error))
      end

      def auth_docs_link_start
        auth_docs_link_url = Rails.application.routes.url_helpers.help_page_path('integration/jira/_index.md', anchor: 'authentication-in-jira')
        link_start(auth_docs_link_url)
      end

      def config_docs_link_start
        config_docs_link_url = Rails.application.routes.url_helpers.help_page_path('integration/jira/configure.md')
        link_start(config_docs_link_url)
      end

      def config_integration_link_start
        config_jira_integration_url = Rails.application.routes.url_helpers.edit_project_settings_integration_path(project, jira_integration)
        link_start(config_jira_integration_url)
      end

      def link_start(url)
        '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: url }
      end

      def error_message(error)
        reportable_error_message(error) ||
          safe_format(s_('JiraRequest|An error occurred while requesting data from Jira. Check your %{docs_link_start}Jira integration configuration%{docs_link_end} and try again.'), docs_link_start: config_docs_link_start, docs_link_end: '</a>'.html_safe)
      end

      # Returns a user-facing error message if possible, otherwise `nil`.
      def reportable_error_message(error)
        case error
        when ERRORS[:jira_ruby]
          reportable_jira_ruby_error_message(error)
        when ERRORS[:ssl]
          s_('JiraRequest|An SSL error occurred while connecting to Jira: %{message}. Try your request again.') % { message: error.message }
        when *ERRORS[:uri]
          s_('JiraRequest|The Jira API URL for connecting to Jira is not valid. Check your Jira integration API URL and try again.')
        when *ERRORS[:timeout]
          s_('JiraRequest|A timeout error occurred while connecting to Jira. Try your request again.')
        when *ERRORS[:connection]
          s_('JiraRequest|A connection error occurred while connecting to Jira. Try your request again.')
        when ERRORS[:url_blocked]
          safe_format(s_('JiraRequest|Unable to connect to the Jira URL. Please verify your %{config_link_start}Jira integration URL%{config_link_end} and attempt the connection again.'), config_link_start: config_integration_link_start, config_link_end: '</a>'.html_safe)
        end
      end

      # Returns a user-facing error message for a `JIRA::HTTPError` if possible,
      # otherwise `nil`.
      def reportable_jira_ruby_error_message(error)
        case error.message
        when 'Unauthorized'
          safe_format(s_('JiraRequest|The credentials for accessing Jira are not valid. Check your %{docs_link_start}Jira integration credentials%{docs_link_end} and try again.'), docs_link_start: auth_docs_link_start, docs_link_end: '</a>'.html_safe)
        when 'Forbidden'
          safe_format(s_('JiraRequest|The credentials for accessing Jira are not allowed to access the data. Check your %{docs_link_start}Jira integration credentials%{docs_link_end} and try again.'), docs_link_start: auth_docs_link_start, docs_link_end: '</a>'.html_safe)
        when 'Bad Request'
          jira_ruby_json_error_message(error.response.body) || safe_format(s_('JiraRequest|An error occurred while requesting data from Jira. Check your %{docs_link_start}Jira integration configuration%{docs_link_end} and try again.'), docs_link_start: config_docs_link_start, docs_link_end: '</a>'.html_safe)
        end
      end

      def jira_ruby_json_error_message(error_message)
        return if error_message.length > JIRA_ERROR_JSON_SIZE_LIMIT

        begin
          messages = Gitlab::Json.parse(error_message)['errorMessages']&.to_sentence
          messages = Rails::Html::FullSanitizer.new.sanitize(messages).presence
          return unless messages

          safe_format(s_('JiraRequest|An error occurred while requesting data from Jira: %{messages} Check your %{docs_link_start}Jira integration configuration%{docs_link_end} and try again.'), messages: messages, docs_link_start: config_docs_link_start, docs_link_end: '</a>'.html_safe)
        rescue JSON::ParserError
        end
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
