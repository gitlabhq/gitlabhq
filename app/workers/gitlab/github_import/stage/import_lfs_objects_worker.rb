# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportLfsObjectsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        sidekiq_options retry: 3
        include GithubImport::Queue
        include StageMethods

        def perform(project_id)
          return unless (project = find_project(project_id))

          import(project)
        end

        # project - An instance of Project.
        def import(project)
          info(project.id, message: "starting importer", importer: 'Importer::LfsObjectsImporter')

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
