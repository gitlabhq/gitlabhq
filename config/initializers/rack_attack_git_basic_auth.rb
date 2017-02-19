rack_attack_enabled = Gitlab.config.rack_attack.['enabled']
git_basic_auth_enabled = Gitlab.config.rack_attack.git_basic_auth['enabled']

unless Rails.env.test? || !rack_attack_enabled || !git_basic_auth_enabled
  # Tell the Rack::Attack Rack middleware to maintain an IP blocklist. We will
  # update the blocklist from GitLab::Auth.rate_limit
  Rack::Attack.blocklist('Git HTTP Basic Auth') do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, Gitlab.config.rack_attack.git_basic_auth) do
      # This block only gets run if the IP was not already banned.
      # Return false, meaning that we do not see anything wrong with the
      # request at this time
      false
    end
  end
end
