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
          importer = importer_class(project)
          return skip_to_next_stage(project) if importer.nil?

          info(project.id, message: "starting importer", importer: importer.name)
          waiter = importer.new(project, client).execute
          move_to_next_stage(project, { waiter.key => waiter.jobs_remaining })
        end

        private

        def importer_class(project)
          if Feature.enabled?(:github_importer_single_endpoint_issue_events_import, project.group, type: :ops)
            ::Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter
          elsif Feature.enabled?(:github_importer_issue_events_import, project.group, type: :ops)
            ::Gitlab::GithubImport::Importer::IssueEventsImporter
          else
            nil
          end
        end

        def skip_to_next_stage(project)
          info(project.id, message: "skipping importer", importer: "IssueEventsImporter")
          move_to_next_stage(project)
        end

        def move_to_next_stage(project, waiters = {})
          AdvanceStageWorker.perform_async(project.id, waiters, :notes)
        end
      end
    end
  end
end
