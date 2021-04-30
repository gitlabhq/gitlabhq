# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        sidekiq_options retry: 3
        include GithubImport::Queue
        include StageMethods

        # technical debt: https://gitlab.com/gitlab-org/gitlab/issues/33991
        sidekiq_options memory_killer_memory_growth_kb: ENV.fetch('MEMORY_KILLER_IMPORT_REPOSITORY_WORKER_MEMORY_GROWTH_KB', 50).to_i
        sidekiq_options memory_killer_max_memory_growth_kb: ENV.fetch('MEMORY_KILLER_IMPORT_REPOSITORY_WORKER_MAX_MEMORY_GROWTH_KB', 300_000).to_i

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          # In extreme cases it's possible for a clone to take more than the
          # import job expiration time. To work around this we schedule a
          # separate job that will periodically run and refresh the import
          # expiration time.
          RefreshImportJidWorker.perform_in_the_future(project.id, jid)

          info(project.id, message: "starting importer", importer: 'Importer::RepositoryImporter')
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
