# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Stage
      class ImportNotesWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        private

        # project - An instance of Project.
        def import(project)
          waiter = importer_class.new(project).execute

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            :lfs_objects
          )
        end

        def importer_class
          Importers::NotesImporter
        end
      end
    end
  end
end
