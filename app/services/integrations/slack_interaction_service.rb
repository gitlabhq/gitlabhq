# frozen_string_literal: true

module Integrations
  class SlackInteractionService
    UnknownInteractionError = Class.new(StandardError)

    INTERACTIONS = {
      'view_closed' => SlackInteractions::IncidentManagement::IncidentModalClosedService,
      'view_submission' => SlackInteractions::IncidentManagement::IncidentModalSubmitService,
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
      service_class.new(params).execute

      ServiceResponse.success
    end

    private

    attr_reader :interaction_type, :params

    def interaction?(type)
      INTERACTIONS.key?(type)
    end
  end
end
