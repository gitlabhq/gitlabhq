# frozen_string_literal: true

module RapidDiffs
  class MergeRequestDiffFileComponent < ViewComponent::Base
    with_collection_parameter :diff_file

    attr_reader :diff_file

    def initialize(diff_file:, merge_request:, parallel_view: false)
      @diff_file = diff_file
      @merge_request = merge_request
      @parallel_view = parallel_view
    end

    def additional_menu_items
      [edit_in_sfe].compact
    end

    def edit_in_sfe
      return unless @diff_file.text?

      editor_path = helpers.project_edit_blob_path(
        @diff_file.repository.project,
        helpers.tree_join(@merge_request.source_branch, @diff_file.new_path),
        from_merge_request_iid: @merge_request.iid
      )

      {
        text: _('Edit in single-file editor'),
        href: editor_path,
        position: 2
      }
    end
  end
end
