# frozen_string_literal: true

module Gitlab
  module JiraImport
    module Stage
      class ImportIssuesWorker # rubocop:disable Scalability/IdempotentWorker
        include Gitlab::JiraImport::ImportWorker

        private

        def import(project)
          jobs_waiter = Gitlab::JiraImport::IssuesImporter.new(
            project,
            project.jira_integration.client(read_timeout: 2.minutes)
          ).execute

          project.latest_jira_import.refresh_jid_expiration

          Gitlab::JiraImport::AdvanceStageWorker.perform_async(
            project.id,
            { jobs_waiter.key => jobs_waiter.jobs_remaining },
            next_stage(project)
          )
        end

        def next_stage(project)
          Gitlab::JiraImport.get_issues_next_start_at(project.id) < 0 ? :attachments : :issues
        end
      end
    end
  end
end
