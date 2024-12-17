# frozen_string_literal: true

class ProjectPresenter < Gitlab::View::Presenter::Delegated
  include ActionView::Helpers::NumberHelper
  include GitlabRoutingHelper
  include StorageHelper
  include TreeHelper
  include Ci::PipelineEditorHelper
  include IconsHelper
  include BlobHelper
  include ChecksCollaboration
  include Gitlab::Utils::StrongMemoize
  include Gitlab::Experiment::Dsl
  include SafeFormatHelper
  include Projects::PagesHelper

  delegator_override_with GitlabRoutingHelper # TODO: Remove `GitlabRoutingHelper` inclusion as it's duplicate
  delegator_override_with Gitlab::Utils::StrongMemoize # This module inclusion is expected. See https://gitlab.com/gitlab-org/gitlab/-/issues/352884.

  presents ::Project, as: :project

  AnchorData = Struct.new(:is_link, :label, :link, :class_modifier, :icon, :itemprop, :data)
  MAX_TOPICS_TO_SHOW = 3

  def statistic_default_class_list
    'icon gl-mr-3 gl-text-subtle'
  end

  def statistic_icon(icon_name = 'plus', class_list = statistic_default_class_list)
    sprite_icon(icon_name, css_class: class_list)
  end

  def statistics_anchors(show_auto_devops_callout:)
    [
      commits_anchor_data,
      branches_anchor_data,
      terraform_states_anchor_data,
      tags_anchor_data,
      storage_anchor_data,
      releases_anchor_data,
      environments_anchor_data
    ].compact.select(&:is_link)
  end

  def statistics_buttons(show_auto_devops_callout:)
    [
      readme_anchor_data,
      license_anchor_data,
      changelog_anchor_data,
      contribution_guide_anchor_data,
      autodevops_anchor_data(show_auto_devops_callout: show_auto_devops_callout),
      kubernetes_cluster_anchor_data,
      gitlab_ci_anchor_data,
      wiki_anchor_data,
      integrations_anchor_data,
      pages_anchor_data
    ].compact.reject(&:is_link).sort_by.with_index { |item, idx| [item.class_modifier ? 0 : 1, idx] }
  end

  def empty_repo_statistics_anchors
    []
  end

  def empty_repo_statistics_buttons
    [
      upload_anchor_data,
      new_file_anchor_data,
      readme_anchor_data,
      license_anchor_data,
      changelog_anchor_data,
      contribution_guide_anchor_data,
      gitlab_ci_anchor_data,
      wiki_anchor_data,
      integrations_anchor_data
    ].compact.reject { |item| item.is_link }
  end

  def default_view
    return anonymous_project_view unless current_user

    user_view = current_user.project_view

    if can?(current_user, :read_code, project)
      user_view
    elsif user_view == 'activity'
      'activity'
    elsif project.wiki_repository_exists? && can?(current_user, :read_wiki, project)
      'wiki'
    elsif can?(current_user, :read_issue, project)
      'projects/issues'
    else
      'activity'
    end
  end

  def readme_path
    filename_path(repository.readme_path)
  end

  def changelog_path
    filename_path(repository.changelog&.name)
  end

  def license_path
    filename_path(repository.license_blob&.name)
  end

  def contribution_guide_path
    if project && contribution_guide = repository.contribution_guide
      project_blob_path(project, tree_join(project.default_branch, contribution_guide.name))
    end
  end

  def add_license_path
    add_special_file_path(file_name: 'LICENSE')
  end

  def add_license_ide_path
    ide_edit_path(project, default_branch_or_main, 'LICENSE')
  end

  def add_changelog_path
    add_special_file_path(file_name: 'CHANGELOG')
  end

  def add_changelog_ide_path
    ide_edit_path(project, default_branch_or_main, 'CHANGELOG')
  end

  def add_contribution_guide_path
    add_special_file_path(file_name: 'CONTRIBUTING.md', commit_message: 'Add CONTRIBUTING')
  end

  def add_contribution_guide_ide_path
    ide_edit_path(project, default_branch_or_main, 'CONTRIBUTING.md')
  end

  def add_readme_path
    add_special_file_path(file_name: 'README.md')
  end

  def add_readme_ide_path
    ide_edit_path(project, default_branch_or_main, 'README.md')
  end

  def license_short_name
    license = repository.license
    license&.nickname || license&.name || 'LICENSE'
  end

  def can_current_user_push_code?
    strong_memoize(:can_current_user_push_code) do
      if empty_repo?
        can?(current_user, :push_code, project)
      else
        can_current_user_push_to_branch?(default_branch)
      end
    end
  end

  def can_current_user_push_to_branch?(branch)
    return false unless current_user

    user_access(project).can_push_to_branch?(branch)
  end

  def can_current_user_push_to_default_branch?
    can_current_user_push_to_branch?(default_branch)
  end

  def storage_anchor_data
    return unless can?(current_user, :admin_project, project) && !empty_repo?

    AnchorData.new(
      true,
      statistic_icon('disk') + storage_anchor_text,
      project_usage_quotas_path(project)
    )
  end

  def releases_anchor_data
    return unless can?(current_user, :read_release, project)

    releases_count = project.releases.count
    return if releases_count < 1

    AnchorData.new(
      true,
      statistic_icon('rocket-launch') +
      safe_format(n_('%{strong_start}%{release_count}%{strong_end} Release', '%{strong_start}%{release_count}%{strong_end} Releases', releases_count), release_count: number_with_delimiter(releases_count), strong_start: '<strong class="project-stat-value">'.html_safe, strong_end: '</strong>'.html_safe),
      project_releases_path(project)
    )
  end

  def environments_anchor_data
    return unless can?(current_user, :read_environment, project)

    environments_count = project.environments.available.count
    return if environments_count == 0

    AnchorData.new(
      true,
      statistic_icon('environment') +
      safe_format(n_('%{strong_start}%{count}%{strong_end} Environment', '%{strong_start}%{count}%{strong_end} Environments', environments_count), count: number_with_delimiter(environments_count), strong_start: '<strong class="project-stat-value">'.html_safe, strong_end: '</strong>'.html_safe),
      project_environments_path(project)
    )
  end

  def commits_anchor_data
    AnchorData.new(
      true,
      statistic_icon('commit') +
      safe_format(n_('%{strong_start}%{commit_count}%{strong_end} Commit', '%{strong_start}%{commit_count}%{strong_end} Commits', statistics.commit_count), commit_count: number_with_delimiter(statistics.commit_count), strong_start: '<strong class="project-stat-value">'.html_safe, strong_end: '</strong>'.html_safe),
      empty_repo? ? nil : project_commits_path(project, default_branch_or_main)
    )
  end

  def branches_anchor_data
    AnchorData.new(
      true,
      statistic_icon('branch') +
      safe_format(n_('%{strong_start}%{branch_count}%{strong_end} Branch', '%{strong_start}%{branch_count}%{strong_end} Branches', repository.branch_count), branch_count: number_with_delimiter(repository.branch_count), strong_start: '<strong class="project-stat-value">'.html_safe, strong_end: '</strong>'.html_safe),
      empty_repo? ? nil : project_branches_path(project)
    )
  end

  def terraform_states_anchor_data
    if project.terraform_states.exists? && can_read_terraform_state?
      terraform_warn_icon = content_tag(
        :span,
        title: s_('Terraform|Support for periods (`.`) in Terraform state names might break existing states.'),
        class: 'gl-ml-2',
        data: { toggle: 'tooltip' }
      ) { sprite_icon('error', css_class: 'gl-fill-icon-subtle') }

      AnchorData.new(
        true,
        statistic_icon('terraform') +
        safe_format(n_('%{strong_start}%{terraform_states_count}%{strong_end} Terraform State', '%{strong_start}%{terraform_states_count}%{strong_end} Terraform States', project.terraform_states.count), terraform_states_count: number_with_delimiter(project.terraform_states.count), strong_start: '<strong class="project-stat-value">'.html_safe, strong_end: '</strong>'.html_safe) + terraform_warn_icon,
        project_terraform_index_path(project)
      )
    end
  end

  def tags_anchor_data
    AnchorData.new(
      true,
      statistic_icon('label') +
      safe_format(n_('%{strong_start}%{tag_count}%{strong_end} Tag', '%{strong_start}%{tag_count}%{strong_end} Tags', repository.tag_count), tag_count: number_with_delimiter(repository.tag_count), strong_start: '<strong class="project-stat-value">'.html_safe, strong_end: '</strong>'.html_safe),
      empty_repo? ? nil : project_tags_path(project)
    )
  end

  def upload_anchor_data
    strong_memoize(:upload_anchor_data) do
      next unless can_current_user_push_to_default_branch?

      AnchorData.new(
        false,
        statistic_icon('upload') + _('Upload file'),
        '#modal-upload-blob',
        'js-upload-file-trigger',
        nil,
        nil,
        {
          'target_branch' => default_branch_or_main,
          'original_branch' => default_branch_or_main,
          'can_push_code' => 'true',
          'can_push_to_branch' => 'true',
          'path' => project_create_blob_path(project, default_branch_or_main),
          'project_path' => project.full_path
        }
      )
    end
  end

  def new_file_anchor_data
    if can_current_user_push_to_default_branch?
      new_file_path = empty_repo? ? ide_edit_path(project, default_branch_or_main) : project_new_blob_path(project, default_branch_or_main)

      AnchorData.new(false, statistic_icon('plus', 'gl-mr-3') + _('New file'), new_file_path)
    end
  end

  def readme_anchor_data
    if can_current_user_push_to_default_branch? && readme_path.nil?
      icon = statistic_icon('plus', 'gl-mr-3')
      label = icon + _('Add README')
      AnchorData.new(false, label, empty_repo? ? add_readme_ide_path : add_readme_path)
    elsif readme_path
      AnchorData.new(
        false,
        statistic_icon('doc-text') + _('README'),
        default_view != 'readme' ? readme_path : '#readme',
        'btn-default',
        'doc-text'
      )
    end
  end

  def changelog_anchor_data
    if can_current_user_push_to_default_branch? && repository.changelog.blank?
      icon = statistic_icon('plus', 'gl-mr-3')
      label = icon + _('Add CHANGELOG')
      AnchorData.new(
        false,
        label,
        empty_repo? ? add_changelog_ide_path : add_changelog_path
      )
    elsif repository.changelog.present?
      AnchorData.new(
        false,
        statistic_icon('doc-text') + _('CHANGELOG'),
        changelog_path,
        'btn-default'
      )
    end
  end

  def license_anchor_data
    icon = statistic_icon('scale')

    if repository.license_blob.present?
      AnchorData.new(
        false,
        icon + content_tag(:span, license_short_name, class: 'project-stat-value'),
        license_path,
        'btn-default',
        nil,
        'license'
      )
    elsif can_current_user_push_to_default_branch?
      icon = statistic_icon('plus', 'gl-mr-3')
      label = icon + _('Add LICENSE')
      AnchorData.new(
        false,
        content_tag(:span, label, class: 'add-license-link gl-flex'),
        empty_repo? ? add_license_ide_path : add_license_path
      )
    end
  end

  def contribution_guide_anchor_data
    if can_current_user_push_to_default_branch? && repository.contribution_guide.blank?
      icon = statistic_icon('plus', 'gl-mr-3')
      label = icon + _('Add CONTRIBUTING')
      AnchorData.new(
        false,
        label,
        empty_repo? ? add_contribution_guide_ide_path : add_contribution_guide_path
      )
    elsif repository.contribution_guide.present?
      AnchorData.new(
        false,
        statistic_icon('doc-text') + _('CONTRIBUTING'),
        contribution_guide_path,
        'btn-default'
      )
    end
  end

  def autodevops_anchor_data(show_auto_devops_callout: false)
    return unless project.feature_available?(:builds, current_user)

    if current_user && can?(current_user, :admin_pipeline, project) && !project.has_ci_config_file? && !show_auto_devops_callout
      if auto_devops_enabled?
        AnchorData.new(
          false,
          statistic_icon('settings') + _('Auto DevOps enabled'),
          project_settings_ci_cd_path(project, anchor: 'autodevops-settings'),
          'btn-default'
        )
      else
        AnchorData.new(
          false,
          content_tag(:span, statistic_icon('plus', 'gl-mr-3') + _('Enable Auto DevOps')),
          project_settings_ci_cd_path(project, anchor: 'autodevops-settings')
        )
      end
    elsif auto_devops_enabled?
      AnchorData.new(false, _('Auto DevOps enabled'), nil)
    end
  end

  def kubernetes_cluster_anchor_data
    if can_instantiate_cluster?
      if clusters.empty?
        AnchorData.new(false, content_tag(:span, statistic_icon('plus', 'gl-mr-3') + _('Add Kubernetes cluster')), project_clusters_path(project))
      else
        cluster_link = clusters.count == 1 ? project_cluster_path(project, clusters.first) : project_clusters_path(project)

        AnchorData.new(false, _('Kubernetes'), cluster_link, 'btn-default')
      end
    end
  end

  def gitlab_ci_anchor_data
    return unless can_view_pipeline_editor?(project)

    if cicd_missing?
      AnchorData.new(false, content_tag(:span, statistic_icon('plus', 'gl-mr-3') + _('Set up CI/CD')), project_ci_pipeline_editor_path(project))
    elsif project.has_ci_config_file?
      AnchorData.new(false, statistic_icon('rocket') + _('CI/CD configuration'), project_ci_pipeline_editor_path(project), 'btn-default')
    end
  end

  def wiki_anchor_data
    return unless project.wiki_enabled? && can_read_wiki?

    if project.wiki.has_home_page?
      AnchorData.new(false, statistic_icon('book') + _('Wiki'), project_wiki_path, 'btn-default', nil, nil)
    elsif can_create_wiki?
      icon = statistic_icon('plus', 'gl-mr-3')
      label = icon + _('Add Wiki')
      AnchorData.new(false, label, project_create_wiki_path, nil, nil, nil)
    end
  end

  def topics_to_show
    project_topic_list.take(MAX_TOPICS_TO_SHOW) # rubocop: disable CodeReuse/ActiveRecord
  end

  def topics_not_shown
    project_topic_list - topics_to_show
  end

  def count_of_extra_topics_not_shown
    if project_topic_list.count > MAX_TOPICS_TO_SHOW
      project_topic_list.count - MAX_TOPICS_TO_SHOW
    else
      0
    end
  end

  def has_extra_topics?
    count_of_extra_topics_not_shown > 0
  end

  def has_review_app?
    !project.environments_for_scope('review/*').empty?
  end

  def can_setup_review_app?
    strong_memoize(:can_setup_review_app) do
      (can_instantiate_cluster? && all_clusters_empty?) || cicd_missing?
    end
  end

  def all_clusters_empty?
    strong_memoize(:all_clusters_empty) do
      project.all_clusters.empty?
    end
  end

  def pages_anchor_data
    return unless project.pages_deployed? && can?(current_user, :read_pages_content, project)

    pages_url = build_pages_url(project)
    AnchorData.new(false, statistic_icon('external-link') + _('GitLab Pages'), pages_url, 'btn-default', nil)
  end

  private

  def integrations_anchor_data
    return unless can?(current_user, :admin_project, project)

    AnchorData.new(false, content_tag(:span, statistic_icon('plus', 'gl-blue-500! gl-mr-3') + _('Configure Integrations')), project_settings_integrations_path(project), nil, nil, nil)
  end

  def cicd_missing?
    current_user && can_current_user_push_code? && !project.has_ci?
  end

  def can_instantiate_cluster?
    current_user && can?(current_user, :create_cluster, project)
  end

  def filename_path(filepath)
    return if filepath.blank?

    project_blob_path(project, tree_join(default_branch, filepath))
  end

  def anonymous_project_view
    if !project.empty_repo? && can?(current_user, :read_code, project)
      'files'
    elsif project.wiki_repository_exists? && can?(current_user, :read_wiki, project)
      'wiki'
    elsif can?(current_user, :read_issue, project)
      'projects/issues'
    else
      'activity'
    end
  end

  def add_special_file_path(file_name:, commit_message: nil, branch_name: nil, additional_params: {})
    commit_message ||= s_("CommitMessage|Add %{file_name}") % { file_name: file_name }
    project_new_blob_path(
      project,
      default_branch_or_main,
      file_name: file_name,
      commit_message: commit_message,
      branch_name: branch_name,
      **additional_params
    )
  end

  def project_topic_list
    strong_memoize(:project_topic_list) do
      project.topics.map { |topic| { name: topic.name, title: topic.title_or_name } }
    end
  end

  def can_read_terraform_state?
    current_user && can?(current_user, :read_terraform_state, project)
  end

  # Avoid including ActionView::Helpers::UrlHelper
  def content_tag(...)
    ActionController::Base.helpers.content_tag(...)
  end

  def can_create_wiki?
    current_user && can?(current_user, :create_wiki, project)
  end

  def can_read_wiki?
    current_user && can?(current_user, :read_wiki, project)
  end

  def project_wiki_path
    wiki_path(project.wiki)
  end

  def project_create_wiki_path
    "#{wiki_path(project.wiki)}?view=create"
  end

  def storage_anchor_text
    safe_format(
      _('%{strong_start}%{human_size}%{strong_end} Project Storage'), {
        human_size: storage_counter(statistics.storage_size),
        strong_start: '<strong class="project-stat-value">'.html_safe,
        strong_end: '</strong>'.html_safe
      }
    )
  end
end

ProjectPresenter.prepend_mod_with('ProjectPresenter')
