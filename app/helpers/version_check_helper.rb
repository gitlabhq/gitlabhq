# frozen_string_literal: true

module VersionCheckHelper
  def version_status_badge
    return unless Rails.env.production?
    return unless Gitlab::CurrentSettings.version_check_enabled
    return if User.single_user&.requires_usage_stats_consent?

    image_url = VersionCheck.new.url
    image_tag image_url, class: 'js-version-status-badge'
  end
end
