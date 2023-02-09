# frozen_string_literal: true

module VersionCheckHelper
  include Gitlab::Utils::StrongMemoize

  SECURITY_ALERT_SEVERITY = 'danger'

  def show_version_check?
    return false unless Gitlab::CurrentSettings.version_check_enabled
    return false if User.single_user&.requires_usage_stats_consent?

    current_user&.can_read_all_resources?
  end

  def gitlab_version_check
    VersionCheck.new.response
  end
  strong_memoize_attr :gitlab_version_check

  def show_security_patch_upgrade_alert?
    return false unless Feature.enabled?(:critical_security_alert) && show_version_check? && gitlab_version_check

    gitlab_version_check['severity'] === SECURITY_ALERT_SEVERITY
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
