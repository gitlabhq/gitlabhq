# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          info(project.id, message: "starting importer", importer: 'Importer::RepositoryImporter')

          # If a user creates an issue while the import is in progress, this can lead to an import failure.
          # The workaround is to allocate IIDs before starting the importer.
          allocate_issues_internal_id!(project, client)

          importer = Importer::RepositoryImporter.new(project, client)

          importer.execute

          counter.increment

          ImportBaseDataWorker.perform_async(project.id)
        end

        def counter
          Gitlab::Metrics.counter(
            :github_importer_imported_repositories,
            'The number of imported GitHub repositories'
          )
        end

        private

        def allocate_issues_internal_id!(project, client)
          return if InternalId.exists?(project: project, usage: :issues) # rubocop: disable CodeReuse/ActiveRecord

          options = { state: 'all', sort: 'number', direction: 'desc', per_page: '1' }
          last_github_issue = client.each_object(:issues, project.import_source, options).first

          return unless last_github_issue

          Issue.track_namespace_iid!(project.project_namespace, last_github_issue[:number])
        end
      end
    end
  end
end
