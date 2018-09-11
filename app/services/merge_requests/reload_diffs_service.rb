# frozen_string_literal: true

module MergeRequests
  class ReloadDiffsService
    def initialize(merge_request, current_user)
      @merge_request = merge_request
      @current_user = current_user
    end

    def execute
      old_diff_refs = merge_request.diff_refs
      new_diff = merge_request.create_merge_request_diff

      clear_cache(new_diff)
      update_diff_discussion_positions(old_diff_refs)
    end

    private

    attr_reader :merge_request, :current_user

    def update_diff_discussion_positions(old_diff_refs)
      new_diff_refs = merge_request.diff_refs

      merge_request.update_diff_discussion_positions(old_diff_refs: old_diff_refs,
                                                     new_diff_refs: new_diff_refs,
                                                     current_user: current_user)
    end

    def clear_cache(new_diff)
      # Executing the iteration we cache highlighted diffs for each diff file of
      # MergeRequestDiff.
      new_diff.diffs_collection.write_cache

      # Remove cache for all diffs on this MR. Do not use the association on the
      # model, as that will interfere with other actions happening when
      # reloading the diff.
      MergeRequestDiff.where(merge_request: merge_request).each do |merge_request_diff|
        next if merge_request_diff == new_diff

        merge_request_diff.diffs_collection.clear_cache
      end
    end
  end
end
