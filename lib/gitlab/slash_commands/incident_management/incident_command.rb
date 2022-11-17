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
      end
    end
  end
end

Gitlab::SlashCommands::IncidentManagement::IncidentCommand.prepend_mod
