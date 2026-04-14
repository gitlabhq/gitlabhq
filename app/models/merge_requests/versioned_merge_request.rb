# frozen_string_literal: true

module MergeRequests
  class VersionedMergeRequest < SimpleDelegator
    extend Gitlab::Utils::DelegatorOverride

    delegator_target ::MergeRequest
    delegator_override :diffs
    delegator_override :class

    def class
      __getobj__.class
    end

    def diffs(diff_options = {})
      return compare.diffs(diff_options.merge(expanded: true)) if compare

      options = diff_options.dup

      version_params = {
        diff_id: options.delete(:diff_id),
        start_sha: options.delete(:start_sha),
        commit_id: options.delete(:commit_id)
      }.compact

      ::Gitlab::MergeRequests::DiffResolver.new(__getobj__, version_params).resolve.diffs(options)
    end
  end
end
