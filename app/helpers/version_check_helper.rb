module VersionCheckHelper
  def version_status_badge
    image_tag VersionCheck.new.url
  end
end
