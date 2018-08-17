# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class PullRequestImporter
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
          @user_finder = UserFinder.new(project, client)
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

          # This work must be wrapped in a transaction as otherwise we can leave
          # behind incomplete data in the event of an error. This can then lead
          # to duplicate key errors when jobs are retried.
          MergeRequest.transaction do
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

            # When creating merge requests there are a lot of hooks that may
            # run, for many different reasons. Many of these hooks (e.g. the
            # ones used for rendering Markdown) are completely unnecessary and
            # may even lead to transaction timeouts.
            #
            # To ensure importing pull requests has a minimal impact and can
            # complete in a reasonable time we bypass all the hooks by inserting
            # the row and then retrieving it. We then only perform the
            # additional work that is strictly necessary.
            merge_request_id = GithubImport
              .insert_and_return_id(attributes, project.merge_requests)

            merge_request = project.merge_requests.find(merge_request_id)

            # We use .insert_and_return_id which effectively disables all callbacks.
            # Trigger iid logic here to make sure we track internal id values consistently.
            merge_request.ensure_target_project_iid!

            [merge_request, false]
          end
        rescue ActiveRecord::InvalidForeignKey
          # It's possible the project has been deleted since scheduling this
          # job. In this case we'll just skip creating the merge request.
          []
        rescue ActiveRecord::RecordNotUnique
          # It's possible we previously created the MR, but failed when updating
          # the Git data. In this case we'll just continue working on the
          # existing row.
          [project.merge_requests.find_by(iid: pull_request.iid), true]
        end

        def insert_git_data(merge_request, already_exists = false)
          # These fields are set so we can create the correct merge request
          # diffs.
          merge_request.source_branch_sha = pull_request.source_branch_sha
          merge_request.target_branch_sha = pull_request.target_branch_sha

          merge_request.keep_around_commit

          # MR diffs normally use an "after_save" hook to pull data from Git.
          # All of this happens in the transaction started by calling
          # create/save/etc. This in turn can lead to these transactions being
          # held open for much longer than necessary. To work around this we
          # first save the diff, then populate it.
          diff =
            if already_exists
              merge_request.merge_request_diffs.take ||
                merge_request.merge_request_diffs.build
            else
              merge_request.merge_request_diffs.build
            end

          diff.importing = true
          diff.save
          diff.save_git_content
        end
      end
    end
  end
end
