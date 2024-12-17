# frozen_string_literal: true

module Commits
  class CherryPickService < ChangeService
    def initialize(*args)
      super

      @start_project = params[:target_project] || @project
      @source_project = params[:source_project] || @project
    end

    def create_commit!
      Gitlab::Git::CrossRepo.new(@project.repository, @source_project.repository).execute(@commit.id) do
        commit_sha = commit_change(:cherry_pick) do |message|
          perform_cherry_pick(message)
        end

        track_mr_picking(commit_sha)

        commit_sha
      end
    end

    private

    def commit_message
      message = commit.cherry_pick_message(current_user)

      co_authored_trailer = "#{Commit::CO_AUTHORED_TRAILER}: #{commit.author_name} <#{commit.author_email}>"

      "#{message}\n\n#{co_authored_trailer}"
    end

    def track_mr_picking(pick_sha)
      merge_request = project.merge_requests.by_merge_commit_sha(@commit.sha).first
      return unless merge_request

      ::SystemNotes::MergeRequestsService.new(
        noteable: merge_request,
        container: project,
        author: current_user
      ).picked_into_branch(@branch_name, pick_sha)
    end

    def perform_cherry_pick(message)
      author_kwargs = { author_name: current_user.name, author_email: current_user.email }

      repository.cherry_pick(current_user, @commit, @branch_name, message,
        start_project: @start_project, start_branch_name: @start_branch, dry_run: @dry_run,
        **author_kwargs
      )
    end
  end
end
