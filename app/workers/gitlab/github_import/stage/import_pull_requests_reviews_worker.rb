# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportPullRequestsReviewsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker
        include GithubImport::Queue
        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          waiter =
            if Feature.enabled?(:github_import_pull_request_reviews, project, default_enabled: true)
              waiter = Importer::PullRequestsReviewsImporter
                .new(project, client)
                .execute

              project.import_state.refresh_jid_expiration

              waiter
            else
              JobWaiter.new
            end

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            :issues_and_diff_notes
          )
        end
      end
    end
  end
end
