# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportProtectedBranchesWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          info(project.id, message: "starting importer", importer: 'Importer::ProtectedBranchesImporter')
          waiter = Importer::ProtectedBranchesImporter
            .new(project, client)
            .execute

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            'lfs_objects'
          )
        end
      end
    end
  end
end
