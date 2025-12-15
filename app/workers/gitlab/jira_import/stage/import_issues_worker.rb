# frozen_string_literal: true

module Gitlab
  module JiraImport
    module Stage
      class ImportIssuesWorker # rubocop:disable Scalability/IdempotentWorker
        include Gitlab::JiraImport::ImportWorker

        private

        def import(project)
          jobs_waiter = Gitlab::JiraImport::IssuesImporter.new(project).execute

          project.latest_jira_import.refresh_jid_expiration

          Gitlab::JiraImport::AdvanceStageWorker.perform_async(
            project.id,
            { jobs_waiter.key => jobs_waiter.jobs_remaining },
            next_stage(project)
          )
        end

        def next_stage(project)
          pagination_state = Gitlab::JiraImport.get_pagination_state(project.id)
          pagination_state[:is_last] ? :attachments : :issues
        end
      end
    end
  end
end
