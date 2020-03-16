# frozen_string_literal: true

module Commits
  class CherryPickService < ChangeService
    def create_commit!
      commit_change(:cherry_pick).tap do |sha|
        track_mr_picking(sha)
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
