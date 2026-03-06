# frozen_string_literal: true

module RapidDiffs
  class DiffTargetVersionEntity < ::RapidDiffs::DiffVersionEntity
    # Overriding the version_index since we want to return `null` version index
    # if the diff is the latest or if it's a HEAD diff. This is so the client
    # can distinguish them in the list of versions and display accordingly.
    expose :version_index do |merge_request_diff|
      next if latest_or_merge_head?(merge_request_diff)

      diff_version_index(merge_request_diff)
    end

    expose :selected do |merge_request_diff|
      next merge_request_diff.head_commit_sha == options[:start_sha] if options[:start_sha].present?
      next true if latest_or_merge_head?(merge_request_diff)

      false
    end

    expose :href do |merge_request_diff|
      next compare_path(merge_request_diff) unless latest_or_merge_head?(merge_request_diff)

      # If diff is latest or HEAD diff, we don't need to return a path with `start_sha`
      # as we should show the latest diff when it is selected.
      diffs_project_merge_request_path(
        merge_request.target_project,
        merge_request,
        path_options
      )
    end

    # We only need this for latest or HEAD diff so client can display the
    # branch if they need to.
    expose :branch, if: ->(diff, _) { latest_or_merge_head?(diff) } do |_|
      merge_request.target_branch
    end

    private

    def compare_path(merge_request_diff)
      merge_request_version_path(
        merge_request.target_project,
        merge_request,
        current_merge_request_diff || merge_request_diffs.first,
        path_options.merge(start_sha: merge_request_diff.head_commit_sha)
      )
    end
  end
end
