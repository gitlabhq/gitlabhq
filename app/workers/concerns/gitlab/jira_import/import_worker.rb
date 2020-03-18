# frozen_string_literal: true

module Gitlab
  module JiraImport
    module ImportWorker
      extend ActiveSupport::Concern

      included do
        include ApplicationWorker
        include Gitlab::JiraImport::QueueOptions
      end

      def perform(project_id)
        project = Project.find_by(id: project_id) # rubocop: disable CodeReuse/ActiveRecord

        return unless can_import?(project)

        import(project)
      end

      private

      def import(project)
        raise NotImplementedError
      end

      def can_import?(project)
        return false unless project
        return false if Feature.disabled?(:jira_issue_import, project)

        project.import_state.started?
      end
    end
  end
end
