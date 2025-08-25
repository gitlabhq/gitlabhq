# frozen_string_literal: true

# Override Rack::Request to make use of the same list of trusted_proxies
# as the ActionDispatch::Request object. This is necessary for libraries
# like rack_attack where they don't use ActionDispatch, and we want them
# to block/throttle requests on private networks.
# Rack Attack specific issue: https://github.com/kickstarter/rack-attack/issues/145
module Rack
  class Request
    def trusted_proxy?(ip)
      Rails.application.config.action_dispatch.trusted_proxies.any? { |proxy| proxy.include?(ip) }
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end

# Trust custom proxies from config.
trusted_proxies = Array(Gitlab.config.gitlab.trusted_proxies).filter_map do |proxy|
  IPAddr.new(proxy)
rescue IPAddr::InvalidAddressError
end

# Default to private IPs if no proxies configured.
trusted_proxies = ActionDispatch::RemoteIp::TRUSTED_PROXIES if trusted_proxies.empty?

# Always trust localhost.
trusted_proxies += [IPAddr.new('127.0.0.1'), IPAddr.new('::1')]

# Trust all proxies in their IPv6 mapped format.
trusted_proxies += trusted_proxies.compact.select(&:ipv4?).map(&:ipv4_mapped)

Rails.application.config.action_dispatch.trusted_proxies = trusted_proxies.uniq

# A monkey patch to make trusted proxies work with Rails 5.0.
# Inspired by https://github.com/rails/rails/issues/5223#issuecomment-263778719
# Remove this monkey patch when upstream is fixed.
module TrustedProxyMonkeyPatch
  def ip
    @ip ||= (get_header("action_dispatch.remote_ip") || super).to_s
  end
end

ActionDispatch::Request.include TrustedProxyMonkeyPatch
