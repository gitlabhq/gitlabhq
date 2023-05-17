# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module PullRequests
        class MergedByImporter
          # pull_request - An instance of
          #                `Gitlab::GithubImport::Representation::PullRequest`
          # project - An instance of `Project`
          # client - An instance of `Gitlab::GithubImport::Client`
          def initialize(pull_request, project, client)
            @pull_request = pull_request
            @project = project
            @client = client
          end

          def execute
            user_finder = GithubImport::UserFinder.new(project, client)

            gitlab_user_id = user_finder.user_id_for(pull_request.merged_by)

            metrics_upsert(gitlab_user_id)

            add_note!
          end

          private

          attr_reader :project, :pull_request, :client

          def metrics_upsert(gitlab_user_id)
            MergeRequest::Metrics.upsert({
              target_project_id: project.id,
              merge_request_id: merge_request.id,
              merged_by_id: gitlab_user_id,
              merged_at: pull_request.merged_at,
              created_at: timestamp,
              updated_at: timestamp
            }, unique_by: :merge_request_id)
          end

          def add_note!
            merge_request.notes.create!(
              importing: true,
              note: missing_author_note,
              author_id: project.creator_id,
              project: project,
              created_at: pull_request.merged_at
            )
          end

          def merge_request
            @merge_request ||= project.merge_requests.find_by_iid(pull_request.iid)
          end

          def timestamp
            @timestamp ||= Time.new.utc
          end

          def missing_author_note
            format(s_("GitHubImporter|*Merged by: %{author} at %{timestamp}*"),
              author: pull_request.merged_by&.login || 'ghost',
              timestamp: pull_request.merged_at
            )
          end
        end
      end
    end
  end
end
