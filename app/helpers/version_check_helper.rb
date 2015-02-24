module VersionCheckHelper
  def version_status_badge
    if File.exists?(Rails.root.join('safe', 'public.pem'))
      image_tag VersionCheck.new.url
    end
  end
end
