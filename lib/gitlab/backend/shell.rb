module Gitlab
  class Shell
    class AccessDenied < StandardError; end

    # Init new repository
    #
    # name - project path with namespace
    #
    # Ex.
    #   add_repository("gitlab/gitlab-ci")
    #
    def add_repository(name)
      system("/home/git/gitlab-shell/bin/gitlab-projects add-project #{name}.git")
    end

    # Remove repository from file system
    #
    # name - project path with namespace
    #
    # Ex.
    #   remove_repository("gitlab/gitlab-ci")
    #
    def remove_repository(name)
      system("/home/git/gitlab-shell/bin/gitlab-projects rm-project #{name}.git")
    end

    # Add new key to gitlab-shell
    #
    # Ex.
    #   add_key("randx", "sha-rsa ...")
    #
    def add_key(username, key_content)
      system("/home/git/gitlab-shell/bin/gitlab-keys add-key #{username} \"#{key_content}\"")
    end

    # Remove ssh key from gitlab shell
    #
    # Ex.
    #   remove_key("sha-rsa")
    #
    def remove_key(key_content)
      system("/home/git/gitlab-shell/bin/gitlab-keys rm-key \"#{key_content}\"")
    end


    def url_to_repo path
      Gitlab.config.gitolite.ssh_path_prefix + "#{path}.git"
    end
  end
end
