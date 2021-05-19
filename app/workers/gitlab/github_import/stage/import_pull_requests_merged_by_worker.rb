# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportPullRequestsMergedByWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        sidekiq_options retry: 3
        include GithubImport::Queue
        include StageMethods

        tags :exclude_from_kubernetes

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          waiter = Importer::PullRequestsMergedByImporter
            .new(project, client)
            .execute

          project.import_state.refresh_jid_expiration

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            :pull_request_reviews
          )
        end
      end
    end
  end
end
