# frozen_string_literal: true

module Gitlab
  module JiraImport
    module Stage
      class FinishImportWorker # rubocop:disable Scalability/IdempotentWorker
        include Gitlab::JiraImport::ImportWorker

        private

        def import(project)
          project.after_import
        ensure
          JiraImport.cache_cleanup(project.id)
          project.import_data.becomes(JiraImportData).finish_import!
          project.import_data.save!
        end
      end
    end
  end
end
