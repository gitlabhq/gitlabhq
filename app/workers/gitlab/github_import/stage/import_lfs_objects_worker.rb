# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportLfsObjectsWorker
        include ApplicationWorker
        include GithubImport::Queue
        include StageMethods

        def perform(project_id)
          return unless (project = find_project(project_id))

          import(project)
        end

        # project - An instance of Project.
        def import(project)
          waiter = Importer::LfsObjectsImporter
            .new(project, nil)
            .execute

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            :finish
          )
        end
      end
    end
  end
end
