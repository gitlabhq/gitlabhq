# frozen_string_literal: true

class ProjectPresenter < Gitlab::View::Presenter::Delegated
  prepend EE::ProjectPresenter

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::UrlHelper
  include GitlabRoutingHelper
  include StorageHelper
  include TreeHelper
  include ChecksCollaboration
  include Gitlab::Utils::StrongMemoize

  presents :project

  AnchorData = Struct.new(:enabled, :label, :link, :class_modifier)
  MAX_TAGS_TO_SHOW = 3

  def statistics_anchors(show_auto_devops_callout:)
    [
      readme_anchor_data,
      changelog_anchor_data,
      contribution_guide_anchor_data,
      files_anchor_data,
      commits_anchor_data,
      branches_anchor_data,
      tags_anchor_data,
      gitlab_ci_anchor_data,
      autodevops_anchor_data(show_auto_devops_callout: show_auto_devops_callout),
      kubernetes_cluster_anchor_data
    ].compact.select { |item| item.enabled }
  end

  def statistics_buttons(show_auto_devops_callout:)
    [
      readme_anchor_data,
      changelog_anchor_data,
      contribution_guide_anchor_data,
      autodevops_anchor_data(show_auto_devops_callout: show_auto_devops_callout),
      kubernetes_cluster_anchor_data,
      gitlab_ci_anchor_data,
      koding_anchor_data
    ].compact.reject { |item| item.enabled }
  end

  def empty_repo_statistics_anchors
    [
      files_anchor_data,
      commits_anchor_data,
      branches_anchor_data,
      tags_anchor_data,
      autodevops_anchor_data,
      kubernetes_cluster_anchor_data
    ].compact.select { |item| item.enabled }
  end

  def empty_repo_statistics_buttons
    [
      new_file_anchor_data,
      readme_anchor_data,
      autodevops_anchor_data,
      kubernetes_cluster_anchor_data
    ].compact.reject { |item| item.enabled }
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
    add_special_file_path(file_name: 'CONTRIBUTING.md', commit_message: 'Add contribution guide')
  end

  def add_ci_yml_path
    add_special_file_path(file_name: '.gitlab-ci.yml')
  end

  def add_readme_path
    add_special_file_path(file_name: 'README.md')
  end

  def add_koding_stack_path
    project_new_blob_path(
      project,
      default_branch || 'master',
      file_name:      '.koding.yml',
      commit_message: "Add Koding stack script",
      content: <<-CONTENT.strip_heredoc
        provider:
          aws:
            access_key: '${var.aws_access_key}'
            secret_key: '${var.aws_secret_key}'
        resource:
          aws_instance:
            #{project.path}-vm:
              instance_type: t2.nano
              user_data: |-

                # Created by GitLab UI for :>

                echo _KD_NOTIFY_@Installing Base packages...@

                apt-get update -y
                apt-get install git -y

                echo _KD_NOTIFY_@Cloning #{project.name}...@

                export KODING_USER=${var.koding_user_username}
                export REPO_URL=#{root_url}${var.koding_queryString_repo}.git
                export BRANCH=${var.koding_queryString_branch}

                sudo -i -u $KODING_USER git clone $REPO_URL -b $BRANCH

                echo _KD_NOTIFY_@#{project.name} cloned.@
      CONTENT
    )
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
                   _('Files (%{human_size})') % { human_size: storage_counter(statistics.total_repository_size) },
                   empty_repo? ? nil : project_tree_path(project))
  end

  def commits_anchor_data
    AnchorData.new(true,
                   n_('Commit (%{commit_count})', 'Commits (%{commit_count})', statistics.commit_count) % { commit_count: number_with_delimiter(statistics.commit_count) },
                   empty_repo? ? nil : project_commits_path(project, repository.root_ref))
  end

  def branches_anchor_data
    AnchorData.new(true,
                   n_('Branch (%{branch_count})', 'Branches (%{branch_count})', repository.branch_count) % { branch_count: number_with_delimiter(repository.branch_count) },
                   empty_repo? ? nil : project_branches_path(project))
  end

  def tags_anchor_data
    AnchorData.new(true,
                   n_('Tag (%{tag_count})', 'Tags (%{tag_count})', repository.tag_count) % { tag_count: number_with_delimiter(repository.tag_count) },
                   empty_repo? ? nil : project_tags_path(project))
  end

  def new_file_anchor_data
    if current_user && can_current_user_push_to_default_branch?
      AnchorData.new(false,
                     _('New file'),
                     project_new_blob_path(project, default_branch || 'master'),
                     'new')
    end
  end

  def readme_anchor_data
    if current_user && can_current_user_push_to_default_branch? && repository.readme.nil?
      AnchorData.new(false,
                     _('Add Readme'),
                     add_readme_path)
    elsif repository.readme
      AnchorData.new(true,
                     _('Readme'),
                     default_view != 'readme' ? readme_path : '#readme')
    end
  end

  def changelog_anchor_data
    if current_user && can_current_user_push_to_default_branch? && repository.changelog.blank?
      AnchorData.new(false,
                     _('Add Changelog'),
                     add_changelog_path)
    elsif repository.changelog.present?
      AnchorData.new(true,
                     _('Changelog'),
                     changelog_path)
    end
  end

  def license_anchor_data
    if repository.license_blob.present?
      AnchorData.new(true,
                     license_short_name,
                     license_path)
    else
      if current_user && can_current_user_push_to_default_branch?
        AnchorData.new(false,
                       _('Add license'),
                       add_license_path)
      else
        AnchorData.new(false,
                       _('No license. All rights reserved'),
                       nil)
      end
    end
  end

  def contribution_guide_anchor_data
    if current_user && can_current_user_push_to_default_branch? && repository.contribution_guide.blank?
      AnchorData.new(false,
                     _('Add Contribution guide'),
                     add_contribution_guide_path)
    elsif repository.contribution_guide.present?
      AnchorData.new(true,
                     _('Contribution guide'),
                     contribution_guide_path)
    end
  end

  def autodevops_anchor_data(show_auto_devops_callout: false)
    if current_user && can?(current_user, :admin_pipeline, project) && repository.gitlab_ci_yml.blank? && !show_auto_devops_callout
      AnchorData.new(auto_devops_enabled?,
                     auto_devops_enabled? ? _('Auto DevOps enabled') : _('Enable Auto DevOps'),
                     project_settings_ci_cd_path(project, anchor: 'autodevops-settings'))
    elsif auto_devops_enabled?
      AnchorData.new(true,
                     _('Auto DevOps enabled'),
                     nil)
    end
  end

  def kubernetes_cluster_anchor_data
    if current_user && can?(current_user, :create_cluster, project)
      cluster_link = clusters.count == 1 ? project_cluster_path(project, clusters.first) : project_clusters_path(project)

      if clusters.empty?
        cluster_link = new_project_cluster_path(project)
      end

      AnchorData.new(!clusters.empty?,
                     clusters.empty? ? _('Add Kubernetes cluster') : _('Kubernetes configured'),
                     cluster_link)
    end
  end

  def gitlab_ci_anchor_data
    if current_user && can_current_user_push_code? && repository.gitlab_ci_yml.blank? && !auto_devops_enabled?
      AnchorData.new(false,
                     _('Set up CI/CD'),
                     add_ci_yml_path)
    elsif repository.gitlab_ci_yml.present?
      AnchorData.new(true,
                     _('CI/CD configuration'),
                     ci_configuration_path)
    end
  end

  def koding_anchor_data
    if current_user && can_current_user_push_code? && koding_enabled? && repository.koding_yml.blank?
      AnchorData.new(false,
                     _('Set up Koding'),
                     add_koding_stack_path)
    end
  end

  def tags_to_show
    project.tag_list.take(MAX_TAGS_TO_SHOW) # rubocop: disable CodeReuse/ActiveRecord
  end

  def count_of_extra_tags_not_shown
    if project.tag_list.count > MAX_TAGS_TO_SHOW
      project.tag_list.count - MAX_TAGS_TO_SHOW
    else
      0
    end
  end

  def has_extra_tags?
    count_of_extra_tags_not_shown > 0
  end

  private

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

  def koding_enabled?
    Gitlab::CurrentSettings.koding_enabled?
  end
end
