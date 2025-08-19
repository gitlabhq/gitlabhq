# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class PullRequestImporter
        include Gitlab::Import::MergeRequestHelpers
        include Gitlab::Import::UsernameMentionRewriter
        include ::Import::PlaceholderReferences::Pusher

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
            issuable_finder.cache_database_id(mr.id)
            set_merge_request_assignees(mr)
            insert_git_data(mr, already_exists)

            push_reference(project, mr, :author_id, pull_request.author&.id)

            # we only import one PR assignee
            assignee = mr.merge_request_assignees.first
            push_reference(project, assignee, :user_id, pull_request.assignee&.id) if assignee
          end
        end

        private

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

          description = MarkdownText.format(pull_request.description, pull_request.author, author_found, project: project)

          attributes = {
            iid: pull_request.iid,
            title: pull_request.truncated_title,
            description: description,
            source_project_id: project.id,
            target_project_id: project.id,
            source_branch: pull_request.formatted_source_branch,
            target_branch: pull_request.target_branch,
            state_id: ::MergeRequest.available_states[pull_request.state],
            milestone_id: milestone_finder.id_for(pull_request),
            author_id: author_id,
            created_at: pull_request.created_at,
            updated_at: pull_request.updated_at,
            imported_from: ::Import::HasImportSource::IMPORT_SOURCES[:github]
          }

          mr = project.merge_requests.new(attributes.merge(importing: true))
          mr.validate!

          create_merge_request_without_hooks(project, attributes, pull_request.iid)
        end

        def set_merge_request_assignees(merge_request)
          assignee_id = user_finder.user_id_for(pull_request[:assignee], ghost: false)

          merge_request.assignee_ids = [assignee_id] if assignee_id
        end

        def insert_git_data(merge_request, already_exists)
          insert_or_replace_git_data(merge_request, pull_request.source_branch_sha, pull_request.target_branch_sha, already_exists)
          # We need to create the branch after the merge request is
          # populated to ensure the merge request is in the right state
          # when the branch is created.
          create_source_branch_if_not_exists(merge_request)
        end

        # An imported merge request will not be mergeable unless the
        # source branch exists. For pull requests from forks, the source
        # branch will be in the form of
        # "github/fork/{project-name}/{source_branch}". This branch will never
        # exist, so we create it here.
        #
        # Note that we only create the branch if the merge request is still open.
        # For projects that have many pull requests, we assume that if it's closed
        # the branch has already been deleted.
        def create_source_branch_if_not_exists(merge_request)
          return unless merge_request.open?

          source_branch = pull_request.formatted_source_branch

          return if project.repository.branch_exists?(source_branch)

          project.repository.add_branch(project.creator, source_branch, pull_request.source_branch_sha)
        rescue Gitlab::Git::PreReceiveError, Gitlab::Git::CommandError => e
          Gitlab::ErrorTracking.track_exception(e,
            source_branch: source_branch,
            project_id: merge_request.project.id,
            merge_request_id: merge_request.id)
        end
      end
    end
  end
end
