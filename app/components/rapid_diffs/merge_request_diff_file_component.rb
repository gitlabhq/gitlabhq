# frozen_string_literal: true

module RapidDiffs
  class MergeRequestDiffFileComponent < ViewComponent::Base
    with_collection_parameter :diff_file

    attr_reader :diff_file

    def initialize(diff_file:, merge_request:, parallel_view: false, plain_view: false)
      @diff_file = diff_file
      @merge_request = merge_request
      @parallel_view = parallel_view
      @plain_view = plain_view
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

    def human_readable_conflict(conflict_type)
      case conflict_type
      when :both_modified then _('Conflict: This file was modified in both the source and target branches.')
      when :modified_source_removed_target then _(
        'Conflict: This file was modified in the source branch, but removed in the target branch.'
      )
      when :modified_target_removed_source then _(
        'Conflict: This file was removed in the source branch, but modified in the target branch.'
      )
      when :renamed_same_file then _(
        'Conflict: This file was renamed differently in the source and target branches.'
      )
      when :removed_source_renamed_target then _(
        'Conflict: This file was removed in the source branch, but renamed in the target branch.'
      )
      when :removed_target_renamed_source then _(
        'Conflict: This file was renamed in the source branch, but removed in the target branch.'
      )
      when :both_added then _(
        'Conflict: This file was added both in the source and target branches, but with different contents.'
      )
      else
        _('Unknown conflict')
      end
    end
  end
end
