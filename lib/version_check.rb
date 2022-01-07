# frozen_string_literal: true

require "base64"

class VersionCheck
  include ReactiveCaching

  self.reactive_cache_work_type = :external_dependency
  self.reactive_cache_worker_finder = ->(_id, *args) { from_cache }

  def self.data
    { version: Gitlab::VERSION }
  end

  def self.headers
    { "REFERER": Gitlab.config.gitlab.url }
  end

  def self.url
    encoded_data = Base64.urlsafe_encode64(data.to_json)

    "#{host}/check.json?gitlab_info=#{encoded_data}"
  end

  def self.host
    'https://version.gitlab.com'
  end

  def self.from_cache(*)
    new
  end

  def id
    Gitlab::VERSION
  end

  def calculate_reactive_cache(*)
    response = Gitlab::HTTP.try_get(self.class.url, headers: self.class.headers)

    case response&.code
    when 200
      response.body
    end
  end

  def response
    with_reactive_cache do |data|
      Gitlab::Json.parse(data) if data
    end
  end
end

VersionCheck.prepend_mod
