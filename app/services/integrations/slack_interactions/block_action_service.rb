# frozen_string_literal: true

module Integrations
  module SlackInteractions
    class BlockActionService
      ALLOWED_UPDATES_HANDLERS = {
        'incident_management_project' => SlackInteractions::SlackBlockActions::IncidentManagement::ProjectUpdateHandler
      }.freeze

      def initialize(params)
        @params = params
      end

      def execute
        actions.each do |action|
          action_id = action[:action_id]

          action_handler_class = handlers[action_id]
          action_handler_class.new(params, action).execute
        end
      end

      private

      def actions
        params[:actions].select { |action| handlers[action[:action_id]] }
      end

      def handlers
        ALLOWED_UPDATES_HANDLERS
      end

      attr_accessor :params
    end
  end
end

Integrations::SlackInteractions::BlockActionService.prepend_mod
