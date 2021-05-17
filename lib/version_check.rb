# frozen_string_literal: true

require "base64"

# This class is used to build image URL to
# check if it is a new version for update
class VersionCheck
  def self.data
    { version: Gitlab::VERSION }
  end

  def self.url
    encoded_data = Base64.urlsafe_encode64(data.to_json)

    "#{host}/check.svg?gitlab_info=#{encoded_data}"
  end

  def self.host
    'https://version.gitlab.com'
  end
end

VersionCheck.prepend_mod
