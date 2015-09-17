# 1. Rename this file to rack_attack.rb
# 2. Review the paths_to_be_protected and add any other path you need protecting
#
# If you change this file in a Merge Request, please also create a Merge Request on https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests

paths_to_be_protected = [
  "#{Gitlab::Application.config.relative_url_root}/users/password",
  "#{Gitlab::Application.config.relative_url_root}/users/sign_in",
  "#{Gitlab::Application.config.relative_url_root}/api/#{API::API.version}/session.json",
  "#{Gitlab::Application.config.relative_url_root}/api/#{API::API.version}/session",
  "#{Gitlab::Application.config.relative_url_root}/users",
  "#{Gitlab::Application.config.relative_url_root}/users/confirmation",
  "#{Gitlab::Application.config.relative_url_root}/unsubscribes/"

]

# Create one big regular expression that matches strings starting with any of
# the paths_to_be_protected.
paths_regex = Regexp.union(paths_to_be_protected.map { |path| /\A#{Regexp.escape(path)}/ })

unless Rails.env.test?
  Rack::Attack.throttle('protected paths', limit: 10, period: 60.seconds) do |req|
    if req.post? && req.path =~ paths_regex
      req.ip
    end
  end
end
