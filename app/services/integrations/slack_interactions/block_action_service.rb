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

          action_handler_class = ALLOWED_UPDATES_HANDLERS[action_id]
          action_handler_class.new(params, action).execute
        end
      end

      private

      def actions
        params[:actions].select { |action| ALLOWED_UPDATES_HANDLERS[action[:action_id]] }
      end

      attr_accessor :params
    end
  end
end
