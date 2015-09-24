module VersionCheckHelper
  def version_status_badge
    if Rails.env.production? && current_application_settings.version_check_enabled
      image_tag VersionCheck.new.url
    end
  end
end
