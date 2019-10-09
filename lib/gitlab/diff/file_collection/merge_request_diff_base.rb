# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      class MergeRequestDiffBase < Base
        extend ::Gitlab::Utils::Override

        def initialize(merge_request_diff, diff_options:)
          @merge_request_diff = merge_request_diff

          super(merge_request_diff,
            project: merge_request_diff.project,
            diff_options: diff_options,
            diff_refs: merge_request_diff.diff_refs,
            fallback_diff_refs: merge_request_diff.fallback_diff_refs)
        end
      end
    end
  end
end
