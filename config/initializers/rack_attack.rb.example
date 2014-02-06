# 1. Rename this file to rack_attack.rb
# 2. Review the paths_to_be_protected and add any other path you need protecting
#

paths_to_be_protected = [
  "#{Rails.application.config.relative_url_root}/users/password",
  "#{Rails.application.config.relative_url_root}/users/sign_in",
  "#{Rails.application.config.relative_url_root}/api/#{API::API.version}/session.json",
  "#{Rails.application.config.relative_url_root}/api/#{API::API.version}/session",
  "#{Rails.application.config.relative_url_root}/users",
  "#{Rails.application.config.relative_url_root}/users/confirmation"
]

unless Rails.env.test?
  Rack::Attack.throttle('protected paths', limit: 10, period: 60.seconds) do |req|
    req.ip if paths_to_be_protected.include?(req.path) && req.post?
  end
end
