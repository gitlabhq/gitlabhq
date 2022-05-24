# frozen_string_literal: true

module MergeRequests
  class ReloadMergeHeadDiffService
    include BaseServiceUtility

    def initialize(merge_request)
      @merge_request = merge_request
    end

    def execute
      return error("Merge request has no merge ref head.") unless merge_request.merge_ref_head.present?

      error_msg = recreate_merge_head_diff

      return error(error_msg) if error_msg

      success
    end

    private

    attr_reader :merge_request

    def recreate_merge_head_diff
      merge_request.merge_head_diff&.destroy!

      # n+1: https://gitlab.com/gitlab-org/gitlab/-/issues/19377
      Gitlab::GitalyClient.allow_n_plus_1_calls do
        merge_request.create_merge_head_diff!
      end

      # Reset the merge request so it won't load the merge head diff as the
      # MergeRequest#merge_request_diff.
      merge_request.reset

      nil
    rescue StandardError => e
      message = "Failed to recreate merge head diff: #{e.message}"

      Gitlab::AppLogger.error(message: message, merge_request_id: merge_request.id)
      message
    end
  end
end

MergeRequests::ReloadMergeHeadDiffService.prepend_mod
