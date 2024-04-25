# frozen_string_literal: true

require "base64"

class VersionCheck
  include ReactiveCaching

  # Increment when format of cache value is changed
  CACHE_VERSION = 1

  ## Version Check Reactive Caching
  ## This cache stores the external API response from https://version.gitlab.com
  ##
  ## Example API Response
  ## {
  ##   "latest_version": "15.2.2",
  ##   "severity": "success"
  ## }
  ##
  ## This response from this endpoint only changes in 2 scenarios:
  ## 1. Customer upgrades their GitLab Instance
  ## 2. GitLab releases a new version
  ##
  ## We use GitLab::VERSION as the identifier for the cached information.
  ## This means if the user upgrades their version we will create a new cache record.
  ## The old one will be invalidated and cleaned up at the end of the self.reactive_cache_lifetime.
  ##
  ## - self.reactive_cache_refresh_interval = 12.hours
  ## We want to prevent as many external API calls as possible to save on resources.
  ## Since an EXISTING cache record will only become "invalid" if GitLab releases a new version we
  ## determined that 12 hour intervals is enough of a window to capture an available upgrade.
  ##
  ## - self.reactive_cache_lifetime = 7.days
  ## We don't want the data to be missing every time a user revisits a page using this info.
  ## Thus 7 days seems like a fair amount of time before we erase the cache.
  ## This also will handle cleaning up old cache records as they will no longer be accessed after an upgrade.
  ##

  self.reactive_cache_refresh_interval = 12.hours
  self.reactive_cache_lifetime = 7.days
  self.reactive_cache_work_type = :external_dependency
  self.reactive_cache_worker_finder = ->(_id, *args) { from_cache }

  def self.data
    { version: Gitlab::VERSION }
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
    [Gitlab::VERSION, Gitlab.revision, CACHE_VERSION].join('-')
  end

  def calculate_reactive_cache(*)
    response = Gitlab::HTTP.try_get(self.class.url)

    case response&.code
    when 200
      Gitlab::Json.parse(response.body)
    else
      { error: 'version check failed', status: response&.code }
    end
  rescue JSON::ParserError
    { error: 'parsing version check response failed', status: response&.code }
  end

  def response
    with_reactive_cache do |data|
      raise InvalidateReactiveCache if !data.is_a?(Hash) || data[:error]

      data
    end
  end
end

VersionCheck.prepend_mod
