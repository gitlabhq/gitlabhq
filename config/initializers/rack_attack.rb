Rack::Attack.throttle('user logins, registration and password reset', limit: 6, period: 60.seconds) do |req|
  req.ip if ["/users/password", "/users/sign_in", "/users"].include?(req.path) && req.post?
end
