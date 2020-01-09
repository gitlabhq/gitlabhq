# frozen_string_literal: true

class ProjectPresenter < Gitlab::View::Presenter::Delegated
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::UrlHelper
  include GitlabRoutingHelper
  include StorageHelper
  include TreeHelper
  include IconsHelper
  include ChecksCollaboration
  include Gitlab::Utils::StrongMemoize

  presents :project

  AnchorData = Struct.new(:is_link, :label, :link, :class_modifier, :icon)
  MAX_TOPICS_TO_SHOW = 3

  def statistic_icon(icon_name = 'plus-square-o')
    sprite_icon(icon_name, size: 16, css_class: 'icon append-right-4')
  end

  def statistics_anchors(show_auto_devops_callout:)
    [
      commits_anchor_data,
      branches_anchor_data,
      tags_anchor_data,
      files_anchor_data
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
      gitlab_ci_anchor_data
    ].compact.reject(&:is_link).sort_by.with_index { |item, idx| [item.class_modifier ? 0 : 1, idx] }
  end

  def empty_repo_statistics_anchors
    []
  end

  def empty_repo_statistics_buttons
    [
      new_file_anchor_data,
      readme_anchor_data,
      license_anchor_data,
      changelog_anchor_data,
      contribution_guide_anchor_data,
      gitlab_ci_anchor_data
    ].compact.reject { |item| item.is_link }
  end

  def default_view
    return anonymous_project_view unless current_user

    user_view = current_user.project_view

    if can?(current_user, :download_code, project)
      user_view
    elsif user_view == "activity"
      "activity"
    elsif can?(current_user, :read_wiki, project)
      "wiki"
    elsif feature_available?(:issues, current_user)
      "projects/issues/issues"
    else
      "customize_workflow"
    end
  end

  def readme_path
    filename_path(:readme)
  end

  def changelog_path
    filename_path(:changelog)
  end

  def license_path
    filename_path(:license_blob)
  end

  def ci_configuration_path
    filename_path(:gitlab_ci_yml)
  end

  def contribution_guide_path
    if project && contribution_guide = repository.contribution_guide
      project_blob_path(
        project,
        tree_join(project.default_branch,
                  contribution_guide.name)
      )
    end
  end

  def add_license_path
    add_special_file_path(file_name: 'LICENSE')
  end

  def add_changelog_path
    add_special_file_path(file_name: 'CHANGELOG')
  end

  def add_contribution_guide_path
    add_special_file_path(file_name: 'CONTRIBUTING.md', commit_message: 'Add CONTRIBUTING')
  end

  def add_ci_yml_path
    add_special_file_path(file_name: '.gitlab-ci.yml')
  end

  def add_readme_path
    add_special_file_path(file_name: 'README.md')
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
    user_access(project).can_push_to_branch?(branch)
  end

  def can_current_user_push_to_default_branch?
    can_current_user_push_to_branch?(default_branch)
  end

  def files_anchor_data
    AnchorData.new(true,
                   statistic_icon('doc-code') +
                   _('%{strong_start}%{human_size}%{strong_end} Files').html_safe % {
                     human_size: storage_counter(statistics.total_repository_size),
                     strong_start: '<strong class="project-stat-value">'.html_safe,
                     strong_end: '</strong>'.html_safe
                   },
                   empty_repo? ? nil : project_tree_path(project))
  end

  def commits_anchor_data
    AnchorData.new(true,
                   statistic_icon('commit') +
                   n_('%{strong_start}%{commit_count}%{strong_end} Commit', '%{strong_start}%{commit_count}%{strong_end} Commits', statistics.commit_count).html_safe % {
                     commit_count: number_with_delimiter(statistics.commit_count),
                     strong_start: '<strong class="project-stat-value">'.html_safe,
                     strong_end: '</strong>'.html_safe
                   },
                   empty_repo? ? nil : project_commits_path(project, repository.root_ref))
  end

  def branches_anchor_data
    AnchorData.new(true,
                   statistic_icon('branch') +
                   n_('%{strong_start}%{branch_count}%{strong_end} Branch', '%{strong_start}%{branch_count}%{strong_end} Branches', repository.branch_count).html_safe % {
                     branch_count: number_with_delimiter(repository.branch_count),
                     strong_start: '<strong class="project-stat-value">'.html_safe,
                     strong_end: '</strong>'.html_safe
                   },
                   empty_repo? ? nil : project_branches_path(project))
  end

  def tags_anchor_data
    AnchorData.new(true,
                   statistic_icon('label') +
                   n_('%{strong_start}%{tag_count}%{strong_end} Tag', '%{strong_start}%{tag_count}%{strong_end} Tags', repository.tag_count).html_safe % {
                     tag_count: number_with_delimiter(repository.tag_count),
                     strong_start: '<strong class="project-stat-value">'.html_safe,
                     strong_end: '</strong>'.html_safe
                   },
                   empty_repo? ? nil : project_tags_path(project))
  end

  def new_file_anchor_data
    if current_user && can_current_user_push_to_default_branch?
      AnchorData.new(false,
                     statistic_icon + _('New file'),
                     project_new_blob_path(project, default_branch || 'master'),
                     'success')
    end
  end

  def readme_anchor_data
    if current_user && can_current_user_push_to_default_branch? && repository.readme.nil?
      AnchorData.new(false,
                     statistic_icon + _('Add README'),
                     add_readme_path)
    elsif repository.readme
      AnchorData.new(false,
                     statistic_icon('doc-text') + _('README'),
                     default_view != 'readme' ? readme_path : '#readme',
                    'default',
                    'doc-text')
    end
  end

  def changelog_anchor_data
    if current_user && can_current_user_push_to_default_branch? && repository.changelog.blank?
      AnchorData.new(false,
                     statistic_icon + _('Add CHANGELOG'),
                     add_changelog_path)
    elsif repository.changelog.present?
      AnchorData.new(false,
                     statistic_icon('doc-text') + _('CHANGELOG'),
                     changelog_path,
                    'default')
    end
  end

  def license_anchor_data
    icon = statistic_icon('scale')

    if repository.license_blob.present?
      AnchorData.new(false,
                     icon + content_tag(:span, license_short_name, class: 'project-stat-value'),
                     license_path,
                     'default')
    else
      if current_user && can_current_user_push_to_default_branch?
        AnchorData.new(false,
                       content_tag(:span, statistic_icon + _('Add LICENSE'), class: 'add-license-link d-flex'),
                       add_license_path)
      else
        AnchorData.new(false,
                       icon + content_tag(:span, _('No license. All rights reserved'), class: 'project-stat-value'),
                       nil)
      end
    end
  end

  def contribution_guide_anchor_data
    if current_user && can_current_user_push_to_default_branch? && repository.contribution_guide.blank?
      AnchorData.new(false,
                     statistic_icon + _('Add CONTRIBUTING'),
                     add_contribution_guide_path)
    elsif repository.contribution_guide.present?
      AnchorData.new(false,
                     statistic_icon('doc-text') + _('CONTRIBUTING'),
                     contribution_guide_path,
                     'default')
    end
  end

  def autodevops_anchor_data(show_auto_devops_callout: false)
    if current_user && can?(current_user, :admin_pipeline, project) && repository.gitlab_ci_yml.blank? && !show_auto_devops_callout
      if auto_devops_enabled?
        AnchorData.new(false,
                       statistic_icon('settings') + _('Auto DevOps enabled'),
                       project_settings_ci_cd_path(project, anchor: 'autodevops-settings'),
                       'default')
      else
        AnchorData.new(false,
                       statistic_icon + _('Enable Auto DevOps'),
                       project_settings_ci_cd_path(project, anchor: 'autodevops-settings'))
      end
    elsif auto_devops_enabled?
      AnchorData.new(false,
                     _('Auto DevOps enabled'),
                     nil)
    end
  end

  def kubernetes_cluster_anchor_data
    if can_instantiate_cluster?
      if clusters.empty?
        AnchorData.new(false,
                       statistic_icon + _('Add Kubernetes cluster'),
                       new_project_cluster_path(project))
      else
        cluster_link = clusters.count == 1 ? project_cluster_path(project, clusters.first) : project_clusters_path(project)

        AnchorData.new(false,
                       _('Kubernetes configured'),
                       cluster_link,
                      'default')
      end
    end
  end

  def gitlab_ci_anchor_data
    if cicd_missing?
      AnchorData.new(false,
                     statistic_icon + _('Set up CI/CD'),
                     add_ci_yml_path)
    elsif repository.gitlab_ci_yml.present?
      AnchorData.new(false,
                     statistic_icon('doc-text') + _('CI/CD configuration'),
                     ci_configuration_path,
                    'default')
    end
  end

  def topics_to_show
    project.tag_list.take(MAX_TOPICS_TO_SHOW) # rubocop: disable CodeReuse/ActiveRecord
  end

  def topics_not_shown
    project.tag_list - topics_to_show
  end

  def count_of_extra_topics_not_shown
    if project.tag_list.count > MAX_TOPICS_TO_SHOW
      project.tag_list.count - MAX_TOPICS_TO_SHOW
    else
      0
    end
  end

  def has_extra_topics?
    count_of_extra_topics_not_shown > 0
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

  private

  def cicd_missing?
    current_user && can_current_user_push_code? && repository.gitlab_ci_yml.blank? && !auto_devops_enabled?
  end

  def can_instantiate_cluster?
    current_user && can?(current_user, :create_cluster, project)
  end

  def filename_path(filename)
    if blob = repository.public_send(filename) # rubocop:disable GitlabSecurity/PublicSend
      project_blob_path(
        project,
        tree_join(default_branch, blob.name)
      )
    end
  end

  def anonymous_project_view
    if !project.empty_repo? && can?(current_user, :download_code, project)
      'files'
    else
      'activity'
    end
  end

  def add_special_file_path(file_name:, commit_message: nil, branch_name: nil)
    commit_message ||= s_("CommitMessage|Add %{file_name}") % { file_name: file_name }
    project_new_blob_path(
      project,
      project.default_branch || 'master',
      file_name:      file_name,
      commit_message: commit_message,
      branch_name:    branch_name
    )
  end
end

ProjectPresenter.prepend_if_ee('EE::ProjectPresenter')
