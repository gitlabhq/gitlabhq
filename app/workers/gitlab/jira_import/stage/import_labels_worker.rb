# frozen_string_literal: true

module Gitlab
  module JiraImport
    module Stage
      class ImportLabelsWorker # rubocop:disable Scalability/IdempotentWorker
        include Gitlab::JiraImport::ImportWorker

        private

        def import(project)
          # fake labels import workers for now
          # new job waiter will have zero jobs_remaining by default, so it will just pass on to next stage
          fake_waiter = JobWaiter.new
          Gitlab::JiraImport::AdvanceStageWorker.perform_async(project.id, { fake_waiter.key => fake_waiter.jobs_remaining }, :issues)
        end
      end
    end
  end
end
