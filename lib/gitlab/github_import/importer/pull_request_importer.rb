# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class PullRequestImporter
        include Gitlab::Import::MergeRequestHelpers

        attr_reader :pull_request, :project, :client, :user_finder,
                    :milestone_finder, :issuable_finder

        # pull_request - An instance of
        #                `Gitlab::GithubImport::Representation::PullRequest`.
        # project - An instance of `Project`
        # client - An instance of `Gitlab::GithubImport::Client`
        def initialize(pull_request, project, client)
          @pull_request = pull_request
          @project = project
          @client = client
          @user_finder = GithubImport::UserFinder.new(project, client)
          @milestone_finder = MilestoneFinder.new(project)
          @issuable_finder =
            GithubImport::IssuableFinder.new(project, pull_request)
        end

        def execute
          mr, already_exists = create_merge_request

          if mr
            insert_git_data(mr, already_exists)
            issuable_finder.cache_database_id(mr.id)
          end
        end

        # Creates the merge request and returns its ID.
        #
        # This method will return `nil` if the merge request could not be
        # created, otherwise it will return an Array containing the following
        # values:
        #
        # 1. A MergeRequest instance.
        # 2. A boolean indicating if the MR already exists.
        def create_merge_request
          author_id, author_found = user_finder.author_id_for(pull_request)

          description = MarkdownText
            .format(pull_request.description, pull_request.author, author_found)

          attributes = {
            iid: pull_request.iid,
            title: pull_request.truncated_title,
            description: description,
            source_project_id: project.id,
            target_project_id: project.id,
            source_branch: pull_request.formatted_source_branch,
            target_branch: pull_request.target_branch,
            state: pull_request.state,
            milestone_id: milestone_finder.id_for(pull_request),
            author_id: author_id,
            assignee_id: user_finder.assignee_id_for(pull_request),
            created_at: pull_request.created_at,
            updated_at: pull_request.updated_at
          }

          create_merge_request_without_hooks(project, attributes, pull_request.iid)
        end

        def insert_git_data(merge_request, already_exists)
          insert_or_replace_git_data(merge_request, pull_request.source_branch_sha, pull_request.target_branch_sha, already_exists)
        end
      end
    end
  end
end
