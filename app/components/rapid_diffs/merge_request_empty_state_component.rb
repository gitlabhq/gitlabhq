# frozen_string_literal: true

module RapidDiffs
  class MergeRequestEmptyStateComponent < ViewComponent::Base
    def initialize(merge_request:, type:)
      @merge_request = merge_request
      @type = type
    end

    private

    attr_reader :merge_request, :type

    def already_merged_description
      helpers.safe_format(
        s_('MergeRequest|All changes from %{sourceStart}%{source}%{sourceEnd} are already present ' \
          'in %{targetStart}%{target}%{targetEnd}.'),
        helpers.tag_pair(helpers.tag.code, :sourceStart, :sourceEnd),
        helpers.tag_pair(helpers.tag.code, :targetStart, :targetEnd),
        source: merge_request.source_branch,
        target: merge_request.target_branch
      )
    end
  end
end
