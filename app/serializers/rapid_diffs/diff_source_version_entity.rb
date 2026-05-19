# frozen_string_literal: true

module RapidDiffs
  class DiffSourceVersionEntity < ::RapidDiffs::DiffVersionEntity
    expose :head_sha do |merge_request_diff| # rubocop:disable Style/SymbolProc -- head_commit_sha takes 0 args; &:head_commit_sha passes options as argument
      merge_request_diff.head_commit_sha
    end

    expose :base_sha do |merge_request_diff| # rubocop:disable Style/SymbolProc -- base_commit_sha takes 0 args; &:base_commit_sha passes options as argument
      merge_request_diff.base_commit_sha
    end

    expose :selected do |merge_request_diff|
      if current_merge_request_diff.present?
        next true if current_merge_request_diff.merge_head? && latest_or_merge_head?(merge_request_diff)

        next merge_request_diff.id == current_merge_request_diff.id
      end

      next true if latest_or_merge_head?(merge_request_diff)

      false
    end

    expose :href do |merge_request_diff|
      next compare_path(merge_request_diff) if options[:start_sha].present?

      merge_request_version_path(
        merge_request.target_project,
        merge_request,
        merge_request_diff
      )
    end

    private

    def compare_path(merge_request_diff)
      merge_request_version_path(
        merge_request.target_project,
        merge_request,
        merge_request_diff,
        { start_sha: options[:start_sha] }
      )
    end
  end
end
