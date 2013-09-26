# To enable rack-attack for your GitLab instance do the following:
# 1. In config/application.rb find and uncomment the following line:
# config.middleware.use Rack::Attack
# 2. Rename this file to rack_attack.rb
# 3. Review the paths_to_be_protected and add any other path you need protecting
# 4. Restart GitLab instance
#

paths_to_be_protected = [
  "#{Rails.application.config.relative_url_root}/users/password",
  "#{Rails.application.config.relative_url_root}/users/sign_in",
  "#{Rails.application.config.relative_url_root}/users"
]
Rack::Attack.throttle('protected paths', limit: 6, period: 60.seconds) do |req|
  req.ip if paths_to_be_protected.include?(req.path) && req.post?
end
