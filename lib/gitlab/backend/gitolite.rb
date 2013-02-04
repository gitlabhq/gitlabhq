module Gitlab
  class Gitolite
    class AccessDenied < StandardError; end

    def config
      Gitlab::GitoliteConfig.new
    end

    # Add new key to gitlab-shell
    #
    # Ex.
    #   add_key("randx", "sha-rsa ...")
    #
    def add_key(username, key_content)
      # TODO: implement
    end

    # Remove ssh key from gitlab shell
    #
    # Ex.
    #   remove_key("sha-rsa")
    #
    def remove_key(key_content)
      # TODO: implement
    end

    # Remove repository from file system
    #
    # name - project path with namespace
    #
    # Ex.
    #   remove_repository("gitlab/gitlab-ci")
    #
    def remove_repository(name)
      # TODO: implement
    end

    # Init new repository
    #
    # name - project path with namespace
    #
    # Ex.
    #   add_repository("gitlab/gitlab-ci")
    #
    def add_repository(name)
      # TODO: implement
    end

    def url_to_repo path
      Gitlab.config.gitolite.ssh_path_prefix + "#{path}.git"
    end

    def enable_automerge
      config.admin_all_repo!
    end
  end
end
