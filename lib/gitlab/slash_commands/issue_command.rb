# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class IssueCommand < BaseCommand
      def self.available?(project)
        project.issues_enabled?
      end

      def collection
        IssuesFinder.new(current_user, project_id: project.id).execute
      end
    end
  end
end
