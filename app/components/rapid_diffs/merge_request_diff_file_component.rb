# frozen_string_literal: true

module RapidDiffs
  class MergeRequestDiffFileComponent < ViewComponent::Base
    with_collection_parameter :diff_file

    attr_reader :diff_file

    def initialize(
      diff_file:, merge_request:, conflict_resolution_path: nil, can_merge: false,
      parallel_view: false, plain_view: false, extra_file_data: {})
      @diff_file = diff_file
      @merge_request = merge_request
      @conflict_resolution_path = conflict_resolution_path
      @can_merge = can_merge
      @parallel_view = parallel_view
      @plain_view = plain_view
      @extra_file_data = extra_file_data
    end

    private

    def extra_file_data
      data = {
        code_review_id: @diff_file.code_review_id,
        blob_raw_path: blob_raw_path
      }
      diff_refs = diff_refs_data
      data[:diff_refs] = diff_refs if diff_refs
      data.merge(@extra_file_data)
    end

    def diff_refs_data
      refs = @diff_file.diff_refs
      return unless refs

      {
        base_sha: refs.base_sha,
        start_sha: refs.start_sha,
        head_sha: refs.head_sha
      }
    end

    def blob_raw_path
      project = @diff_file.repository.project
      helpers.project_raw_path(project, helpers.tree_join(@diff_file.content_sha, @diff_file.file_path))
    end

    def extra_options
      return {} unless show_viewed_toggle?

      { data: { code_review_id: @diff_file.code_review_id } }
    end

    def show_viewed_toggle?
      @diff_file.code_review_id.present?
    end

    def viewed_checkbox_id
      "code-review-#{@diff_file.code_review_id[0..8]}"
    end

    def additional_menu_items
      [edit_in_sfe].compact
    end

    def edit_in_sfe
      return unless @diff_file.text?
      return if @diff_file.stored_externally?
      return unless @merge_request.source_project

      editor_path = helpers.project_edit_blob_path(
        @merge_request.source_project,
        helpers.tree_join(@merge_request.source_branch, @diff_file.new_path),
        from_merge_request_iid: @merge_request.iid
      )

      {
        text: _('Edit single file'),
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

    def conflict_resolution_message
      return _('Ask someone with write access to resolve it.') unless @can_merge

      if @conflict_resolution_path
        helpers.safe_format(
          _('You can %{gitlabLinkStart}resolve conflicts on GitLab%{gitlabLinkEnd} or ' \
            '%{resolveLocallyStart}resolve them locally%{resolveLocallyEnd}.'),
          helpers.tag_pair(resolve_on_gitlab_link, :gitlabLinkStart, :gitlabLinkEnd),
          helpers.tag_pair(resolve_locally_button, :resolveLocallyStart, :resolveLocallyEnd)
        )
      else
        helpers.safe_format(
          _('You can %{resolveLocallyStart}resolve them locally%{resolveLocallyEnd}.'),
          helpers.tag_pair(resolve_locally_button, :resolveLocallyStart, :resolveLocallyEnd)
        )
      end
    end

    def resolve_on_gitlab_link
      helpers.link_to('', @conflict_resolution_path)
    end

    def resolve_locally_button
      helpers.render(
        Pajamas::ButtonComponent.new(
          category: :tertiary,
          variant: :link,
          button_options: { type: 'button', data: { click: 'resolveConflictsLocally' } }
        )
      )
    end
  end
end
