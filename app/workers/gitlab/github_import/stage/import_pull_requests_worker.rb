# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportPullRequestsWorker
        include ApplicationWorker
        include GithubImport::Queue
        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          waiter = Importer::PullRequestsImporter
            .new(project, client)
            .execute

          project.refresh_import_jid_expiration

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
