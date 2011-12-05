require File.join(Rails.root, "lib", "gitlabhq", "gitolite")
require File.join(Rails.root, "lib", "gitlabhq", "gitosis")

module Gitlabhq
  class GitHost
    def self.system
      if GIT_HOST["system"] == "gitosis"
        Gitlabhq::Gitosis
      else 
        Gitlabhq::Gitolite
      end
    end

    def self.admin_uri
      GIT_HOST["admin_uri"]
    end
  end
end
