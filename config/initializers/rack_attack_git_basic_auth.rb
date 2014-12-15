unless Rails.env.test?
  Rack::Attack.blacklist('Git HTTP Basic Auth') do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, Gitlab.config.rack_attack.git_basic_auth) do
      # This block only gets run if the IP was not already banned.
      # Return false, meaning that we do not see anything wrong with the
      # request at this time
      false
    end
  end
end
