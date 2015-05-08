require "base64"

# This class is used to build image URL to
# check if it is a new version for update
class VersionCheck
  def data
    { version: Gitlab::VERSION }
  end

  def url
    encoded_data = Base64.urlsafe_encode64(data.to_json)
    "#{host}?gitlab_info=#{encoded_data}"
  end

  # FIXME: Replace with version.gitlab.com
  def host
    'http://localhost:9090/check.png'
  end
end
