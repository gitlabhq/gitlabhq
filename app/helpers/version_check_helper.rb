module VersionCheckHelper
  def version_status_badge
    if Rails.env.production? && Gitlab::CurrentSettings.version_check_enabled
      image_url = VersionCheck.new.url
      image_tag image_url, class: 'js-version-status-badge'
    end
  end
end
