# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module IncidentManagement
      class IncidentCommand < BaseCommand
        def self.available?(project)
          true
        end

        def collection
          IssuesFinder.new(current_user, project_id: project.id, issue_types: :incident).execute
        end

        def slack_installation
          slack_workspace_id = params[:team_id]

          SlackIntegration.with_bot.find_by_team_id(slack_workspace_id)
        end
      end
    end
  end
end
