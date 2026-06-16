# frozen_string_literal: true

module MergeRequests
  class VersionedMergeRequest < SimpleDelegator
    extend Gitlab::Utils::DelegatorOverride

    delegator_target ::MergeRequest
    delegator_override :diffs
    delegator_override :diff_stats
    delegator_override :class
    delegator_override :has_coverage_reports?
    delegator_override :has_codequality_reports?

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

    def changes_already_in_target?
      return false unless resolved_version.try(:merge_head?) && diffable_merge_ref?
      return false if latest_merge_request_diff.nil? || latest_merge_request_diff.empty?

      resolved_version.empty?
    end

    def has_coverage_reports?
      return false unless latest_diff_version?

      __getobj__.has_coverage_reports_for?(latest_diff_head_pipeline)
    end

    def has_codequality_reports?
      return false unless latest_diff_version?

      __getobj__.has_codequality_reports_for?(latest_diff_head_pipeline)
    end

    private

    # Reports map onto the right lines only when the latest version is the diff target;
    # they are produced for its head pipeline and not for older versions or context commits.
    def latest_diff_version?
      return false if __getobj__.show_context_commits_diff?(@version_params)

      diff_resolver.latest?
    end

    # Avoid `diff_head_pipeline`: it derives `diff_head_sha` from the `merge_request_diff`
    # association, which can be pinned to a non-latest version while rendering. Anchor to the
    # latest diff head instead so report availability reflects the latest pipeline.
    def latest_diff_head_pipeline
      head_pipeline = __getobj__.head_pipeline
      sha = __getobj__.latest_merge_request_diff&.head_commit_sha
      head_pipeline if sha && head_pipeline&.matches_sha_or_source_sha?(sha)
    end

    def resolved_version
      @resolved_version ||= diff_resolver.resolve
    end

    def diff_resolver
      @diff_resolver ||= ::Gitlab::MergeRequests::DiffResolver.new(__getobj__, @version_params)
    end
  end
end
