# frozen_string_literal: true

class MergeRequestNoteableEntity < IssuableEntity
  include RequestAwareEntity

  # Currently this attr is exposed to be used in app/assets/javascripts/notes/stores/getters.js
  # in order to determine whether a noteable is an issue or an MR
  expose :merge_params

  expose :state
  expose :source_branch
  expose :target_branch

  expose :source_branch_path, if: ->(merge_request) { merge_request.source_project } do |merge_request|
    project_tree_path(merge_request.source_project, merge_request.source_branch)
  end

  expose :target_branch_path, if: ->(merge_request) { merge_request.target_project } do |merge_request|
    project_tree_path(merge_request.target_project, merge_request.target_branch)
  end

  expose :diff_head_sha

  expose :create_note_path do |merge_request|
    project_notes_path(merge_request.project, target_type: 'merge_request', target_id: merge_request.id)
  end

  expose :preview_note_path do |merge_request|
    preview_markdown_path(merge_request.project, target_type: 'MergeRequest', target_id: merge_request.iid)
  end

  expose :supports_suggestion?, as: :can_receive_suggestion

  expose :create_issue_to_resolve_discussions_path do |merge_request|
    presenter(merge_request).create_issue_to_resolve_discussions_path
  end

  expose :new_blob_path do |merge_request|
    if presenter(merge_request).can_push_to_source_branch?
      project_new_blob_path(merge_request.source_project, merge_request.source_branch)
    end
  end

  expose :current_user do
    expose :can_create_note do |merge_request|
      can?(current_user, :create_note, merge_request)
    end

    expose :can_update do |merge_request|
      can?(current_user, :update_merge_request, merge_request)
    end

    expose :can_create_confidential_note do |merge_request|
      can?(request.current_user, :mark_note_as_internal, merge_request)
    end
  end

  expose :locked_discussion_docs_path, if: ->(merge_request) { merge_request.discussion_locked? } do |merge_request|
    help_page_path('user/discussions/_index.md', anchor: 'prevent-comments-by-locking-the-discussion')
  end

  expose :is_project_archived do |merge_request|
    merge_request.project.archived?
  end

  expose :project_id

  expose :archived_project_docs_path, if: ->(merge_request) { merge_request.project.archived? } do |merge_request|
    help_page_path('user/project/working_with_projects.md', anchor: 'delete-a-project')
  end

  private

  delegate :current_user, to: :request

  def presenter(merge_request)
    @presenters ||= {}
    @presenters[merge_request] ||= MergeRequestPresenter.new(merge_request, current_user: current_user) # rubocop: disable CodeReuse/Presenter
  end
end

MergeRequestNoteableEntity.prepend_mod_with('MergeRequestNoteableEntity')
