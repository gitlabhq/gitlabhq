# frozen_string_literal: true

module RapidDiffs
  class DiffSourceVersionEntity < ::RapidDiffs::DiffVersionEntity
    expose :selected do |merge_request_diff|
      next merge_request_diff.id == current_merge_request_diff.id if current_merge_request_diff.present?
      next true if latest_or_merge_head?(merge_request_diff)

      false
    end

    expose :href do |merge_request_diff|
      next compare_path(merge_request_diff) if options[:start_sha].present?

      merge_request_version_path(
        merge_request.target_project,
        merge_request,
        merge_request_diff,
        path_options
      )
    end

    private

    def compare_path(merge_request_diff)
      merge_request_version_path(
        merge_request.target_project,
        merge_request,
        merge_request_diff,
        path_options.merge(start_sha: options[:start_sha])
      )
    end
  end
end
