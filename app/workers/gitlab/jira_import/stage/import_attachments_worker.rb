# frozen_string_literal: true

module Gitlab
  module JiraImport
    module Stage
      class ImportAttachmentsWorker # rubocop:disable Scalability/IdempotentWorker
        include Gitlab::JiraImport::ImportWorker

        private

        def import(project)
          # fake a attahcments import workers for now.
          # new job waiter will have zero jobs_remaining by default, so it will just pass on to next stage
          fake_waiter = JobWaiter.new

          project.latest_jira_import.refresh_jid_expiration
          Gitlab::JiraImport::AdvanceStageWorker.perform_async(project.id, { fake_waiter.key => fake_waiter.jobs_remaining }, :notes)
        end
      end
    end
  end
end
