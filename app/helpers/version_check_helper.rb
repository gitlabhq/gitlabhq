# frozen_string_literal: true

module VersionCheckHelper
  def version_status_badge
    return unless Rails.env.production?
    return unless Gitlab::CurrentSettings.version_check_enabled
    return if User.single_user&.requires_usage_stats_consent?

    image_tag VersionCheck.url, class: 'js-version-status-badge'
  end

  def link_to_version
    if Gitlab.pre_release?
      commit_link = link_to(Gitlab.revision, source_host_url + namespace_project_commits_path(source_code_group, source_code_project, Gitlab.revision))
      [Gitlab::VERSION, content_tag(:small, commit_link)].join(' ').html_safe
    else
      link_to Gitlab::VERSION, source_host_url + namespace_project_tag_path(source_code_group, source_code_project, "v#{Gitlab::VERSION}")
    end
  end

  def source_host_url
    Gitlab::Saas.com_url
  end

  def source_code_group
    'gitlab-org'
  end

  def source_code_project
    'gitlab-foss'
  end
end

VersionCheckHelper.prepend_mod
