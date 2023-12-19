# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportPullRequestsReviewRequestsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        include StageMethods

        resumes_work_when_interrupted!

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          waiter = Importer::PullRequests::ReviewRequestsImporter
           .new(project, client)
           .execute

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            'pull_request_reviews'
          )
        end
      end
    end
  end
end
