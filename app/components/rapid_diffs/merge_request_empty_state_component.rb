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

    def no_changes_description
      helpers.safe_format(
        _('No changes between %{source} and %{target}'),
        source: helpers.tag.span(merge_request.source_branch, class: 'ref-name'),
        target: helpers.tag.span(merge_request.target_branch, class: 'ref-name')
      )
    end

    # Mirrors MergeRequestNoteableEntity/MergeRequestPollWidgetEntity: the
    # "Create commit" link is only offered when the user can push to the
    # source branch. When they cannot, no link (and therefore no button) is
    # rendered.
    def new_blob_path
      return unless merge_request.present(current_user: helpers.current_user).can_push_to_source_branch?

      helpers.project_new_blob_path(merge_request.source_project, merge_request.source_branch)
    end
  end
end
