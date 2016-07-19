# 1. Rename this file to rack_attack.rb
# 2. Review the paths_to_be_protected and add any other path you need protecting
#
# If you change this file in a Merge Request, please also create a Merge Request on https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests

paths_to_be_protected = [
  "#{Rails.application.config.relative_url_root}/users/password",
  "#{Rails.application.config.relative_url_root}/users/sign_in",
  "#{Rails.application.config.relative_url_root}/api/#{API::API.version}/session.json",
  "#{Rails.application.config.relative_url_root}/api/#{API::API.version}/session",
  "#{Rails.application.config.relative_url_root}/users",
  "#{Rails.application.config.relative_url_root}/users/confirmation",
  "#{Rails.application.config.relative_url_root}/unsubscribes/",
  "#{Rails.application.config.relative_url_root}/import/github/personal_access_token"

]

# Create one big regular expression that matches strings starting with any of
# the paths_to_be_protected.
paths_regex = Regexp.union(paths_to_be_protected.map { |path| /\A#{Regexp.escape(path)}/ })
rack_attack_enabled = Gitlab.config.rack_attack.git_basic_auth['enabled']

unless Rails.env.test? || !rack_attack_enabled
  Rack::Attack.throttle('protected paths', limit: 10, period: 60.seconds) do |req|
    if req.post? && req.path =~ paths_regex
      req.ip
    end
  end
end
