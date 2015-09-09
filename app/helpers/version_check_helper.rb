module VersionCheckHelper
  def version_status_badge
    if Rails.env.production?
      image_tag VersionCheck.new.url
    end
  end
end
