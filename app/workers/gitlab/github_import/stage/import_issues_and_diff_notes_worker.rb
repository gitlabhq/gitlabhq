# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportIssuesAndDiffNotesWorker
        include ApplicationWorker
        include GithubImport::Queue
        include StageMethods

        # The importers to run in this stage. Issues can't be imported earlier
        # on as we also use these to enrich pull requests with assigned labels.
        IMPORTERS = [
          Importer::IssuesImporter,
          Importer::DiffNotesImporter
        ].freeze

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          waiters = IMPORTERS.each_with_object({}) do |klass, hash|
            waiter = klass.new(project, client).execute
            hash[waiter.key] = waiter.jobs_remaining
          end

          AdvanceStageWorker.perform_async(project.id, waiters, :notes)
        end
      end
    end
  end
end
