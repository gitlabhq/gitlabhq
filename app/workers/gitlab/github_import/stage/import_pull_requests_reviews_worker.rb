# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportPullRequestsReviewsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        include StageMethods

        resumes_work_when_interrupted!

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          waiter = Importer::PullRequests::ReviewsImporter
            .new(project, client)
            .execute

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            'issues_and_diff_notes'
          )
        end
      end
    end
  end
end
