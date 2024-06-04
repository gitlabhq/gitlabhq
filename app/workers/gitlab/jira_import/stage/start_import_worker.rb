# frozen_string_literal: true

module Gitlab
  module JiraImport
    module Stage
      class StartImportWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        include ProjectStartImport
        include ProjectImportOptions
        include Gitlab::JiraImport::QueueOptions

        sidekiq_options retry: 6

        attr_reader :project

        def perform(project_id)
          @project = Project.find_by_id(project_id)

          return unless start_import

          Gitlab::Import::SetAsyncJid.set_jid(project.latest_jira_import)

          Gitlab::JiraImport::Stage::ImportLabelsWorker.perform_async(project.id)
        end

        private

        def start_import
          return false unless project
          return true if start(project.latest_jira_import)

          ::Import::Framework::Logger.info(
            {
              project_id: project.id,
              project_path: project.full_path,
              state: project&.jira_import_status,
              message: 'inconsistent state while importing'
            }
          )
          false
        end
      end
    end
  end
end
