# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportNotesWorker
        include ApplicationWorker
        include GithubImport::Queue
        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          waiter = Importer::NotesImporter
            .new(project, client)
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
