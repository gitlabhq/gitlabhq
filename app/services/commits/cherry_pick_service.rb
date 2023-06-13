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
        commit_change(:cherry_pick).tap do |sha|
          track_mr_picking(sha)
        end
      end
    end

    private

    def track_mr_picking(pick_sha)
      merge_request = project.merge_requests.by_merge_commit_sha(@commit.sha).first
      return unless merge_request

      ::SystemNotes::MergeRequestsService.new(
        noteable: merge_request,
        project: project,
        author: current_user
      ).picked_into_branch(@branch_name, pick_sha)
    end
  end
end
