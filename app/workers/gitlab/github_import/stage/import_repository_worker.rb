# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportRepositoryWorker
        include ApplicationWorker
        include GithubImport::Queue
        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          # In extreme cases it's possible for a clone to take more than the
          # import job expiration time. To work around this we schedule a
          # separate job that will periodically run and refresh the import
          # expiration time.
          RefreshImportJidWorker.perform_in_the_future(project.id, jid)

          importer = Importer::RepositoryImporter.new(project, client)

          return unless importer.execute

          counter.increment

          ImportBaseDataWorker.perform_async(project.id)
        end

        def counter
          Gitlab::Metrics.counter(
            :github_importer_imported_repositories,
            'The number of imported GitHub repositories'
          )
        end
      end
    end
  end
end
