# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportIssueEventsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        include StageMethods

        resumes_work_when_interrupted!

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          return skip_to_next_stage(project) if skip_to_next_stage?(project)

          importer = ::Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter
          info(project.id, message: "starting importer", importer: importer.name)
          waiter = importer.new(project, client).execute
          move_to_next_stage(project, { waiter.key => waiter.jobs_remaining })
        end

        private

        def skip_to_next_stage?(project)
          # This stage is mandatory when using extended_events
          return false if import_settings(project).extended_events?

          import_settings(project).disabled?(:single_endpoint_issue_events_import)
        end

        def skip_to_next_stage(project)
          info(project.id, message: "skipping importer", importer: "IssueEventsImporter")
          move_to_next_stage(project)
        end

        def move_to_next_stage(project, waiters = {})
          AdvanceStageWorker.perform_async(project.id, waiters.deep_stringify_keys, next_stage(project))
        end

        def next_stage(project)
          return "attachments" if import_settings(project).extended_events?

          "notes"
        end
      end
    end
  end
end
