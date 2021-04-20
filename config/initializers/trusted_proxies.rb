# frozen_string_literal: true

# Override Rack::Request to make use of the same list of trusted_proxies
# as the ActionDispatch::Request object. This is necessary for libraries
# like rack_attack where they don't use ActionDispatch, and we want them
# to block/throttle requests on private networks.
# Rack Attack specific issue: https://github.com/kickstarter/rack-attack/issues/145
module Rack
  class Request
    def trusted_proxy?(ip)
      Rails.application.config.action_dispatch.trusted_proxies.any? { |proxy| proxy === ip }
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end

gitlab_trusted_proxies = Array(Gitlab.config.gitlab.trusted_proxies).map do |proxy|
  IPAddr.new(proxy)
rescue IPAddr::InvalidAddressError
end.compact

Rails.application.config.action_dispatch.trusted_proxies = (
  ['127.0.0.1', '::1'] + gitlab_trusted_proxies)

# A monkey patch to make trusted proxies work with Rails 5.0.
# Inspired by https://github.com/rails/rails/issues/5223#issuecomment-263778719
# Remove this monkey patch when upstream is fixed.
module TrustedProxyMonkeyPatch
  def ip
    @ip ||= (get_header("action_dispatch.remote_ip") || super).to_s
  end
end

ActionDispatch::Request.include TrustedProxyMonkeyPatch
