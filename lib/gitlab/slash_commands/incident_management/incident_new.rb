# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module IncidentManagement
      class IncidentNew < IncidentCommand
        def self.help_message
          'incident declare'
        end

        def self.allowed?(project, user)
          Feature.enabled?(:incident_declare_slash_command, user) && can?(user, :create_incident, project)
        end

        def self.match(text)
          text == 'incident declare'
        end

        def execute(_match)
          response = ServiceResponse.success(message: 'It works!')

          presenter.present(response.message)
        end

        private

        def presenter
          Gitlab::SlashCommands::Presenters::IncidentManagement::IncidentNew.new
        end
      end
    end
  end
end
