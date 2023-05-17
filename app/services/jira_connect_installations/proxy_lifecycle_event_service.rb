# frozen_string_literal: true

module JiraConnectInstallations
  class ProxyLifecycleEventService
    SUPPOERTED_EVENTS = %i[installed uninstalled].freeze

    def self.execute(installation, event, instance_url)
      new(installation, event, instance_url).execute
    end

    def initialize(installation, event, instance_url)
      # To ensure the event is sent to the right instance, this makes
      # a copy of the installation and assigns the instance_url
      #
      # The installation might be modified already with a new instance_url.
      # This can be the case for an uninstalled event.
      # The installation is updated first, and the uninstalled event has to be sent to
      # the old instance_url.
      @installation = installation.dup
      @installation.instance_url = instance_url

      @event = event.to_sym

      raise(ArgumentError, "Unknown event '#{@event}'") unless SUPPOERTED_EVENTS.include?(@event)
    end

    def execute
      result = send_hook

      return ServiceResponse.new(status: :success) if result.code == 200

      log_unsuccessful_response(result.code, result.body)

      ServiceResponse.error(message: { type: :response_error, code: result.code })
    rescue *Gitlab::HTTP::HTTP_ERRORS => error
      ServiceResponse.error(message: { type: :network_error, message: error.message })
    end

    private

    attr_reader :installation, :event

    def send_hook
      Gitlab::HTTP.post(hook_uri, body: body)
    end

    def hook_uri
      case event
      when :installed
        installation.audience_installed_event_url
      when :uninstalled
        installation.audience_uninstalled_event_url
      end
    end

    def body
      return base_body unless event == :installed

      base_body.merge(installed_body)
    end

    def base_body
      {
        clientKey: installation.client_key,
        jwt: jwt_token,
        eventType: event
      }
    end

    def installed_body
      {
        sharedSecret: installation.shared_secret,
        baseUrl: installation.base_url
      }
    end

    def jwt_token
      @jwt_token ||= JiraConnect::CreateAsymmetricJwtService.new(@installation, event: event).execute
    end

    def log_unsuccessful_response(status_code, body)
      Gitlab::IntegrationsLogger.info(
        integration: 'JiraConnect',
        message: 'Proxy lifecycle event received error response',
        jira_event_type: event,
        jira_status_code: status_code,
        jira_body: body
      )
    end
  end
end
