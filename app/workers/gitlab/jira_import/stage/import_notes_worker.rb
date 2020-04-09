# frozen_string_literal: true

module Gitlab
  module JiraImport
    module Stage
      class ImportNotesWorker # rubocop:disable Scalability/IdempotentWorker
        include Gitlab::JiraImport::ImportWorker

        private

        def import(project)
          # fake notes import workers for now
          # new job waiter will have zero jobs_remaining by default, so it will just pass on to next stage
          jobs_waiter = JobWaiter.new
          project.latest_jira_import.refresh_jid_expiration

          Gitlab::JiraImport::AdvanceStageWorker.perform_async(project.id, { jobs_waiter.key => jobs_waiter.jobs_remaining }, :finish)
        end
      end
    end
  end
end
