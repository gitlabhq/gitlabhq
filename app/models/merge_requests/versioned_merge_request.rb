# frozen_string_literal: true

module MergeRequests
  class VersionedMergeRequest < SimpleDelegator
    extend Gitlab::Utils::DelegatorOverride

    delegator_target ::MergeRequest
    delegator_override :diffs
    delegator_override :diff_stats
    delegator_override :class

    VERSION_KEYS = %i[diff_id start_sha commit_id only_context_commits].freeze

    def self.from_diff_options(merge_request, diff_options)
      new(merge_request, version_params: diff_options.slice(*VERSION_KEYS).compact)
    end

    def initialize(merge_request, version_params: {})
      super(merge_request)
      @version_params = version_params
    end

    def class
      __getobj__.class
    end

    def diffs(diff_options = {})
      return compare.diffs(diff_options.merge(expanded: true)) if compare
      return context_commits_diff.diffs(diff_options) if __getobj__.show_context_commits_diff?(diff_options)

      resolved_version.diffs(diff_options.except(*VERSION_KEYS))
    end

    def diff_stats
      return __getobj__.diff_stats if compare
      return context_commits_diff.diff_stats if __getobj__.show_context_commits_diff?(@version_params)

      resolved_version.diff_stats
    end

    private

    def resolved_version
      @resolved_version ||= ::Gitlab::MergeRequests::DiffResolver.new(__getobj__, @version_params).resolve
    end
  end
end
