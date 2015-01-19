unless Rails.env.test?
  # Tell the Rack::Attack Rack middleware to maintain an IP blacklist. We will
  # update the blacklist from Grack::Auth#authenticate_user.
  Rack::Attack.blacklist('Git HTTP Basic Auth') do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, Gitlab.config.rack_attack.git_basic_auth) do
      # This block only gets run if the IP was not already banned.
      # Return false, meaning that we do not see anything wrong with the
      # request at this time
      false
    end
  end
end
