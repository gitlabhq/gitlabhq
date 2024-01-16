# frozen_string_literal: true

module Gitlab
  module JiraImport
    module ImportWorker
      extend ActiveSupport::Concern

      included do
        include ApplicationWorker

        include ProjectImportOptions
        include Gitlab::JiraImport::QueueOptions
        sidekiq_options retry: 6
      end

      def perform(project_id)
        project = Project.find_by_id(project_id)

        return unless can_import?(project)

        import(project)
      end

      private

      def import(project)
        raise NotImplementedError
      end

      def can_import?(project)
        return false unless project

        project.latest_jira_import&.started?
      end
    end
  end
end
