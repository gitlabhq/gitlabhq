# Tell the Rack::Attack Rack middleware to maintain an IP blacklist.
# We update the blacklist in Gitlab::Auth::IpRateLimiter.
Rack::Attack.blocklist('Git HTTP Basic Auth') do |req|
  next false unless Gitlab.config.rack_attack.git_basic_auth.enabled

  Rack::Attack::Allow2Ban.filter(req.ip, Gitlab.config.rack_attack.git_basic_auth) do
    # This block only gets run if the IP was not already banned.
    # Return false, meaning that we do not see anything wrong with the
    # request at this time
    false
  end
end
