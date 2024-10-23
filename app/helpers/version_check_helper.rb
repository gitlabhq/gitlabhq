# frozen_string_literal: true

module VersionCheckHelper
  include Gitlab::Utils::StrongMemoize

  def show_version_check?
    return false unless Gitlab::CurrentSettings.version_check_enabled

    current_user&.can_admin_all_resources? && !User.single_user&.requires_usage_stats_consent?
  end

  def gitlab_version_check
    return unless show_version_check?

    VersionCheck.new.response
  end
  strong_memoize_attr :gitlab_version_check

  def show_security_patch_upgrade_alert?
    return false unless gitlab_version_check

    Gitlab::Utils.to_boolean(gitlab_version_check['critical_vulnerability'])
  end

  def link_to_version
    link = link_to(Gitlab::Source.ref, Gitlab::Source.release_url)

    if Gitlab.pre_release?
      [Gitlab::VERSION, content_tag(:small, link)].join(' ').html_safe
    else
      link
    end
  end
end
