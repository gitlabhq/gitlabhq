# frozen_string_literal: true

class MergeRequestWidgetEntity < Grape::Entity
  include RequestAwareEntity

  # Currently this attr is exposed to be used in app/assets/javascripts/notes/stores/getters.js
  # in order to determine whether a noteable is an issue or an MR
  expose :merge_params

  expose :source_project_full_path do |merge_request|
    merge_request.source_project&.full_path
  end

  expose :target_project_full_path do |merge_request|
    merge_request.project&.full_path
  end

  expose :email_patches_path do |merge_request|
    project_merge_request_path(merge_request.project, merge_request, format: :patch)
  end

  expose :plain_diff_path do |merge_request|
    project_merge_request_path(merge_request.project, merge_request, format: :diff)
  end

  expose :merge_request_basic_path do |merge_request|
    project_merge_request_path(merge_request.target_project, merge_request, serializer: :basic, format: :json)
  end

  expose :merge_request_widget_path do |merge_request|
    widget_project_json_merge_request_path(merge_request.target_project, merge_request, format: :json)
  end

  expose :merge_request_cached_widget_path do |merge_request|
    cached_widget_project_json_merge_request_path(merge_request.target_project, merge_request, format: :json)
  end

  expose :create_note_path do |merge_request|
    project_notes_path(merge_request.project, target_type: 'merge_request', target_id: merge_request.id)
  end

  expose :commit_change_content_path do |merge_request|
    commit_change_content_project_merge_request_path(merge_request.project, merge_request)
  end

  expose :preview_note_path do |merge_request|
    preview_markdown_path(merge_request.project, target_type: 'MergeRequest', target_id: merge_request.iid)
  end

  expose :conflicts_docs_path do |merge_request|
    help_page_path('user/project/merge_requests/resolve_conflicts.md')
  end

  expose :merge_request_pipelines_docs_path do |merge_request|
    help_page_path('ci/merge_request_pipelines/index.md')
  end

  expose :ci_environments_status_path do |merge_request|
    ci_environments_status_project_merge_request_path(merge_request.project, merge_request)
  end

  # Rendering and redacting Markdown can be expensive. These links are
  # just nice to have in the merge request widget, so only
  # include them if they are explicitly requested on first load.
  expose :issues_links, if: -> (_, opts) { opts[:issues_links] } do
    expose :assign_to_closing do |merge_request|
      presenter(merge_request).assign_to_closing_issues_link
    end

    expose :closing do |merge_request|
      presenter(merge_request).closing_issues_links
    end

    expose :mentioned_but_not_closing do |merge_request|
      presenter(merge_request).mentioned_issues_links
    end
  end

  def as_json(options = {})
    super(options)
      .merge(MergeRequestPollCachedWidgetEntity.new(object, **@options.opts_hash).as_json(options))
      .merge(MergeRequestPollWidgetEntity.new(object, **@options.opts_hash).as_json(options))
  end

  private

  def presenter(merge_request)
    @presenters ||= {}
    @presenters[merge_request] ||= MergeRequestPresenter.new(merge_request, current_user: request.current_user) # rubocop: disable CodeReuse/Presenter
  end
end
