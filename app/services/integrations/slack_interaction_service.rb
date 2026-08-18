# frozen_string_literal: true

module Integrations
  class SlackInteractionService
    UnknownInteractionError = Class.new(StandardError)

    INTERACTIONS = {
      'view_closed' => SlackInteractions::IncidentManagement::IncidentModalClosedService,
      'view_submission' => SlackInteractions::ViewSubmissionService,
      'block_actions' => SlackInteractions::BlockActionService
    }.freeze

    def initialize(params)
      @interaction_type = params.delete(:type)
      @params = params
    end

    def execute
      raise UnknownInteractionError, "Unable to handle interaction type: '#{interaction_type}'" \
        unless interaction?(interaction_type)

      service_class = INTERACTIONS[interaction_type]
      response = service_class.new(params).execute

      ServiceResponse.success(payload: slack_response_payload(response))
    end

    private

    attr_reader :interaction_type, :params

    def interaction?(type)
      INTERACTIONS.key?(type)
    end

    # Slack acts on the interaction endpoint's HTTP response body (for example
    # `response_action` on view_submission). Only propagate payloads that are
    # explicitly meant for Slack; anything else stays an empty body.
    def slack_response_payload(response)
      return {} unless response.is_a?(ServiceResponse)
      return {} unless response.payload.is_a?(Hash) && response.payload.key?(:response_action)

      response.payload
    end
  end
end
