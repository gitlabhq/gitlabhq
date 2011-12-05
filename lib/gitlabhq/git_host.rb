require File.join(Rails.root, "lib", "gitlabhq", "gitolite")

module Gitlabhq
  class GitHost
    def self.system
      Gitlabhq::Gitolite
    end

    def self.admin_uri
      GIT_HOST["admin_uri"]
    end

    def self.url_to_repo(path)
      if !GIT_HOST["port"] or GIT_HOST["port"] == 22
        "#{GIT_HOST["git_user"]}@#{GIT_HOST["host"]}:#{path}.git"
      else
        "ssh://#{GIT_HOST["git_user"]}@#{GIT_HOST["host"]}:#{GIT_HOST["port"]}/#{path}.git"
      end
    end
  end
end
