# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportPullRequestsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        sidekiq_options retry: 3
        include GithubImport::Queue
        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          info(project.id, message: "starting importer", importer: 'Importer::PullRequestsImporter')

          # If a user creates a new merge request while the import is in progress, GitLab can assign an IID
          # to this merge request that already exists for a GitHub Pull Request.
          # The workaround is to allocate IIDs before starting the importer.
          allocate_merge_requests_internal_id!(project, client)

          waiter = Importer::PullRequestsImporter
            .new(project, client)
            .execute

          project.import_state.refresh_jid_expiration

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            :collaborators
          )
        rescue StandardError => e
          Gitlab::Import::ImportFailureService.track(
            project_id: project.id,
            error_source: self.class.name,
            exception: e,
            fail_import: abort_on_failure,
            metrics: true
          )

          raise(e)
        end

        private

        def allocate_merge_requests_internal_id!(project, client)
          return if InternalId.exists?(project: project, usage: :merge_requests) # rubocop: disable CodeReuse/ActiveRecord

          options = { state: 'all', sort: 'number', direction: 'desc', per_page: '1' }
          last_github_pull_request = client.each_object(:pulls, project.import_source, options).first

          return unless last_github_pull_request

          MergeRequest.track_target_project_iid!(project, last_github_pull_request[:number])
        end

        def abort_on_failure
          true
        end
      end
    end
  end
end
