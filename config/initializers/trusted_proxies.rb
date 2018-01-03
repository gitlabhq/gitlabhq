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
  begin
    IPAddr.new(proxy)
  rescue IPAddr::InvalidAddressError
  end
end.compact

Rails.application.config.action_dispatch.trusted_proxies = (
  ['127.0.0.1', '::1'] + gitlab_trusted_proxies)
