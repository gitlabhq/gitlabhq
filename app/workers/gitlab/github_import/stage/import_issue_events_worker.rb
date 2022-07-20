# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportIssueEventsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        sidekiq_options retry: 3
        include GithubImport::Queue
        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          importer = ::Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter
          return skip_to_next_stage(project, importer) if feature_disabled?(project)

          start_importer(project, importer, client)
        end

        private

        def start_importer(project, importer, client)
          info(project.id, message: "starting importer", importer: importer.name)
          waiter = importer.new(project, client).execute
          move_to_next_stage(project, waiter.key => waiter.jobs_remaining)
        end

        def skip_to_next_stage(project, importer)
          info(project.id, message: "skipping importer", importer: importer.name)
          move_to_next_stage(project)
        end

        def move_to_next_stage(project, waiters = {})
          AdvanceStageWorker.perform_async(project.id, waiters, :notes)
        end

        def feature_disabled?(project)
          Feature.disabled?(:github_importer_issue_events_import, project.group, type: :ops)
        end
      end
    end
  end
end
