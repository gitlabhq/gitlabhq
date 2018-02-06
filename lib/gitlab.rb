require_dependency 'gitlab/git'

module Gitlab
  COM_URL = 'https://gitlab.com'.freeze

  def self.com?
    # Check `staging?` as well to keep parity with gitlab.com
    Gitlab.config.gitlab.url == COM_URL || staging?
  end

  def self.staging?
    Gitlab.config.gitlab.url == 'https://staging.gitlab.com'
  end
end
