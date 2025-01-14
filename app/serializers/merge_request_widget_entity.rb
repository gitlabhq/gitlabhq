# frozen_string_literal: true

class MergeRequestWidgetEntity < Grape::Entity
  include RequestAwareEntity
  include ProjectsHelper
  include ApplicationHelper
  include ApplicationSettingsHelper

  SUGGEST_PIPELINE = 'suggest_pipeline'
  MIGRATE_FROM_JENKINS_BANNER = 'migrate_from_jenkins_banner'

  expose :id
  expose :iid

  expose :source_project_full_path do |merge_request|
    merge_request.source_project&.full_path
  end

  expose :target_project_full_path do |merge_request|
    merge_request.project&.full_path
  end

  expose :can_create_pipeline_in_target_project do |merge_request|
    can?(current_user, :create_pipeline, merge_request.target_project)
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

  expose :commit_change_content_path do |merge_request|
    commit_change_content_project_merge_request_path(merge_request.project, merge_request)
  end

  expose :conflicts_docs_path do |merge_request|
    help_page_path('user/project/merge_requests/conflicts.md')
  end

  expose :reviewing_and_managing_merge_requests_docs_path do |merge_request|
    help_page_path('user/project/merge_requests/merge_request_troubleshooting.md', anchor: "check-out-merge-requests-locally-through-the-head-ref")
  end

  expose :merge_request_pipelines_docs_path do |merge_request|
    help_page_path('ci/pipelines/merge_request_pipelines.md')
  end

  expose :ci_environments_status_path do |merge_request|
    ci_environments_status_project_merge_request_path(merge_request.project, merge_request)
  end

  expose :merge_request_add_ci_config_path, if: ->(mr, _) { can_add_ci_config_path?(mr) } do |merge_request|
    project = merge_request.source_project
    params = {
      branch_name: merge_request.source_branch,
      add_new_config_file: true
    }
    project_ci_pipeline_editor_path(project, params)
  end

  expose :user_callouts_path do |_merge_request|
    callouts_path
  end

  expose :suggest_pipeline_feature_id do |_merge_request|
    SUGGEST_PIPELINE
  end

  expose :migrate_jenkins_feature_id do |_merge_request|
    MIGRATE_FROM_JENKINS_BANNER
  end

  expose :is_dismissed_suggest_pipeline do |_merge_request|
    next true unless current_user
    next true unless Gitlab::CurrentSettings.suggest_pipeline_enabled?

    current_user.dismissed_callout?(feature_name: SUGGEST_PIPELINE)
  end

  expose :is_dismissed_jenkins_migration do |_merge_request|
    next true unless current_user
    next true unless Gitlab::CurrentSettings.show_migrate_from_jenkins_banner?

    current_user.dismissed_callout?(feature_name: MIGRATE_FROM_JENKINS_BANNER)
  end

  expose :human_access do |merge_request|
    merge_request.project.team.human_max_access(current_user&.id)
  end

  expose :new_project_pipeline_path do |merge_request|
    new_project_pipeline_path(merge_request.project)
  end

  expose :source_project_default_url do |merge_request|
    merge_request.source_project && default_url_to_repo(merge_request.source_project)
  end

  # Rendering and redacting Markdown can be expensive. These links are
  # just nice to have in the merge request widget, so only
  # include them if they are explicitly requested on first load.
  expose :issues_links, if: ->(_, opts) { opts[:issues_links] } do
    expose :assign_to_closing do |merge_request|
      presenter(merge_request).assign_to_closing_issues_path
    end

    expose :assign_to_closing_count do |merge_request|
      presenter(merge_request).assign_to_closing_issues_count
    end

    expose :closing do |merge_request|
      presenter(merge_request).closing_issues_links
    end

    expose :closing_count do |merge_request|
      presenter(merge_request).closing_issues.size
    end

    expose :mentioned_but_not_closing do |merge_request|
      presenter(merge_request).mentioned_issues_links
    end

    expose :mentioned_count do |merge_request|
      presenter(merge_request).mentioned_issues.size
    end
  end

  expose :security_reports_docs_path do |merge_request|
    help_page_path('user/application_security/detect/security_scan_results.md', anchor: 'merge-request')
  end

  expose :enabled_reports do |merge_request|
    merge_request.enabled_reports
  end

  expose :show_gitpod_button do |merge_request|
    Gitlab::CurrentSettings.gitpod_enabled
  end

  expose :gitpod_url do |merge_request|
    next unless Gitlab::CurrentSettings.gitpod_enabled

    gitpod_url = Gitlab::CurrentSettings.gitpod_url
    context_url = project_merge_request_url(merge_request.project, merge_request)

    "#{gitpod_url}##{context_url}"
  end

  expose :gitpod_enabled do |merge_request|
    current_user&.gitpod_enabled || false
  end

  private

  delegate :current_user, to: :request

  def presenter(merge_request)
    @presenters ||= {}
    @presenters[merge_request] ||= MergeRequestPresenter.new(merge_request, current_user: current_user) # rubocop: disable CodeReuse/Presenter
  end

  def can_add_ci_config_path?(merge_request)
    merge_request.open? &&
      merge_request.source_branch_exists? &&
      !merge_request.source_project.has_ci? &&
      merge_request.commits_count > 0 &&
      can?(current_user, :read_build, merge_request.source_project) &&
      can?(current_user, :create_pipeline, merge_request.source_project)
  end

  def head_pipeline_downloadable_path_for_report_type(file_type)
    object.head_pipeline&.present(current_user: current_user)
      &.downloadable_path_for_report_type(file_type)
  end

  def base_pipeline_downloadable_path_for_report_type(file_type)
    object.base_pipeline&.present(current_user: current_user)
      &.downloadable_path_for_report_type(file_type)
  end

  def merge_base_pipeline_downloadable_path_for_report_type(file_type)
    object.merge_base_pipeline&.present(current_user: current_user)
      &.downloadable_path_for_report_type(file_type)
  end
end

MergeRequestWidgetEntity.prepend_mod_with('MergeRequestWidgetEntity')
