require 'gitlab/git'

module Gitlab
  def self.com?
    Gitlab.config.gitlab.url == 'https://gitlab.com'
  end
end
