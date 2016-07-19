require_dependency 'gitlab/git'

module Gitlab
  def self.com?
    # Check `staging?` as well to keep parity with gitlab.com
    Gitlab.config.gitlab.url == 'https://gitlab.com' || staging?
  end

  def self.staging?
    Gitlab.config.gitlab.url == 'https://staging.gitlab.com'
  end
end
