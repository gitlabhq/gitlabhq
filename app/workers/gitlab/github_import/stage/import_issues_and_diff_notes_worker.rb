# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportIssuesAndDiffNotesWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        include StageMethods

        resumes_work_when_interrupted!

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          waiters = importers.each_with_object({}) do |klass, hash|
            info(
              project.id,
              message: "starting importer",
              importer: klass.name,
              Labkit::Fields::GL_ORGANIZATION_ID => project.organization_id
            )
            waiter = klass.new(project, client).execute
            hash[waiter.key] = waiter.jobs_remaining
          end

          AdvanceStageWorker.perform_async(project.id, waiters.deep_stringify_keys, 'issue_events')
        end

        # The importers to run in this stage. Issues can't be imported earlier
        # on as we also use these to enrich pull requests with assigned labels.
        def importers
          [
            Importer::IssuesImporter,
            Importer::SingleEndpointDiffNotesImporter
          ]
        end
      end
    end
  end
end
