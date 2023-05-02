# frozen_string_literal: true

# Performs the initial handling of event payloads sent from Slack to GitLab.
# See `API::Integrations::Slack::Events` which calls this service.
module Integrations
  class SlackEventService
    URL_VERIFICATION_EVENT = 'url_verification'

    UnknownEventError = Class.new(StandardError)

    def initialize(params)
      # When receiving URL verification events, params[:type] is 'url_verification'.
      # For all other events we subscribe to, params[:type] is 'event_callback' and
      # the specific type of the event will be in params[:event][:type].
      # Remove both of these from the params before they are passed to the services.
      type = params.delete(:type)
      type = params[:event].delete(:type) if type == 'event_callback'

      @slack_event = type
      @params = params
    end

    def execute
      raise UnknownEventError, "Unable to handle event type: '#{slack_event}'" unless routable_event?

      payload = route_event

      ServiceResponse.success(payload: payload)
    end

    private

    # The `url_verification` slack_event response must be returned to Slack in-request,
    # so for this event we call the service directly instead of through a worker.
    #
    # All other events must be handled asynchronously in order to return a 2xx response
    # immediately to Slack in the request. See https://api.slack.com/apis/connections/events-api.
    def route_in_request?
      slack_event == URL_VERIFICATION_EVENT
    end

    def routable_event?
      route_in_request? || route_to_event_worker?
    end

    def route_to_event_worker?
      SlackEventWorker.event?(slack_event)
    end

    # Returns a payload for the service response.
    def route_event
      return SlackEvents::UrlVerificationService.new(params).execute if route_in_request?

      SlackEventWorker.perform_async(slack_event: slack_event, params: params)

      {}
    end

    attr_reader :slack_event, :params
  end
end
