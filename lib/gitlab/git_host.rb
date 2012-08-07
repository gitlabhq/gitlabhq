require File.join(Rails.root, "lib", "gitlab", "gitolite")

module Gitlab
  class GitHost
    def self.system
      Gitlab::Gitolite
    end

    def self.admin_uri
      url_to_repo "gitolite-admin"
    end

    def self.url_to_repo(path)
      Gitlab.config.ssh_path + "#{path}.git"
    end
  end
end
