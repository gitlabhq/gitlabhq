# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module IncidentManagement
      class IncidentNew < IncidentCommand
        def self.help_message
          'incident declare *(Beta)*'
        end

        def self.allowed?(_project, _user)
          Feature.enabled?(:incident_declare_slash_command)
        end

        def self.match(text)
          text == 'incident declare'
        end

        def execute(_match)
          response = ::Integrations::SlackInteractions::IncidentManagement::IncidentModalOpenedService
          .new(slack_installation, current_user, params)
          .execute

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

Gitlab::SlashCommands::IncidentManagement::IncidentNew.prepend_mod
