Rails.application.config.action_dispatch.trusted_proxies = (
  [ '127.0.0.1', '::1' ] + Array(Gitlab.config.gitlab.trusted_proxies)
).map { |proxy| IPAddr.new(proxy) }
