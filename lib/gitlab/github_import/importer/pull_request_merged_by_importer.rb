# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class PullRequestMergedByImporter
        def initialize(pull_request, project, client)
          @project = project
          @pull_request = pull_request
          @client = client
        end

        def execute
          merge_request = project.merge_requests.find_by_iid(pull_request.iid)
          timestamp = Time.new.utc
          merged_at = pull_request.merged_at
          user_finder = GithubImport::UserFinder.new(project, client)
          gitlab_user_id = user_finder.user_id_for(pull_request.merged_by)

          MergeRequest::Metrics.upsert({
            target_project_id: project.id,
            merge_request_id: merge_request.id,
            merged_by_id: gitlab_user_id,
            merged_at: merged_at,
            created_at: timestamp,
            updated_at: timestamp
          }, unique_by: :merge_request_id)

          unless gitlab_user_id
            merge_request.notes.create!(
              importing: true,
              note: missing_author_note,
              author_id: project.creator_id,
              project: project,
              created_at: merged_at
            )
          end
        end

        private

        attr_reader :project, :pull_request, :client

        def missing_author_note
          s_("GitHubImporter|*Merged by: %{author} at %{timestamp}*") % {
            author: pull_request.merged_by&.login || 'ghost',
            timestamp: pull_request.merged_at
          }
        end
      end
    end
  end
end
