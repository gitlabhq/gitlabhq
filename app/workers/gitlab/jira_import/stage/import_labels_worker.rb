# frozen_string_literal: true

module Gitlab
  module JiraImport
    module Stage
      class ImportLabelsWorker # rubocop:disable Scalability/IdempotentWorker
        include Gitlab::JiraImport::ImportWorker

        private

        def import(project)
          job_waiter = Gitlab::JiraImport::LabelsImporter.new(project).execute
          Gitlab::JiraImport::AdvanceStageWorker.perform_async(project.id, { job_waiter.key => job_waiter.jobs_remaining }, :issues)
        end
      end
    end
  end
end
