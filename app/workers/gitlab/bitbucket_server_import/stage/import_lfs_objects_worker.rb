# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Stage
      class ImportLfsObjectsWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        resumes_work_when_interrupted!

        private

        # project - An instance of Project.
        def import(project)
          waiter = importer_class.new(project).execute

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            :finish
          )
        end

        def importer_class
          Importers::LfsObjectsImporter
        end
      end
    end
  end
end
