# frozen_string_literal: true

module Gitlab
  module JiraImport
    module Stage
      class StartImportWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker
        include ProjectStartImport
        include ProjectImportOptions
        include Gitlab::JiraImport::QueueOptions

        attr_reader :project

        def perform(project_id)
          @project = Project.find_by(id: project_id) # rubocop: disable CodeReuse/ActiveRecord

          return unless start_import

          Gitlab::Import::SetAsyncJid.set_jid(project)

          Gitlab::JiraImport::Stage::ImportLabelsWorker.perform_async(project.id)
        end

        private

        def start_import
          return false unless project
          return false if Feature.disabled?(:jira_issue_import, project)
          return true if start(project.import_state)

          Gitlab::Import::Logger.info(
            {
              project_id: project.id,
              project_path: project.full_path,
              state: project&.import_status,
              message: 'inconsistent state while importing'
            }
          )
          false
        end
      end
    end
  end
end
