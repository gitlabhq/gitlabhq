# frozen_string_literal: true

module Gitlab
  module JiraImport
    module Stage
      class FinishImportWorker # rubocop:disable Scalability/IdempotentWorker
        include Gitlab::JiraImport::ImportWorker

        private

        def import(project)
          JiraImport.cache_cleanup(project.id)
          project.latest_jira_import.finish!
        end
      end
    end
  end
end
