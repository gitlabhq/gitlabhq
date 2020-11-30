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
          user_finder = GithubImport::UserFinder.new(project, client)
          gitlab_user_id = user_finder.user_id_for(pull_request.merged_by)

          if gitlab_user_id
            timestamp = Time.new.utc
            MergeRequest::Metrics.upsert({
              target_project_id: project.id,
              merge_request_id: merge_request.id,
              merged_by_id: gitlab_user_id,
              created_at: timestamp,
              updated_at: timestamp
            }, unique_by: :merge_request_id)
          else
            merge_request.notes.create!(
              importing: true,
              note: "*Merged by: #{pull_request.merged_by.login}*",
              author_id: project.creator_id,
              project: project,
              created_at: pull_request.created_at
            )
          end
        end

        private

        attr_reader :project, :pull_request, :client
      end
    end
  end
end
