# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportIssuesAndDiffNotesWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        sidekiq_options retry: 3
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
            info(project.id, message: "starting importer", importer: klass.name)
            waiter = klass.new(project, client).execute
            hash[waiter.key] = waiter.jobs_remaining
          end

          AdvanceStageWorker.perform_async(project.id, waiters, :notes)
        end
      end
    end
  end
end
