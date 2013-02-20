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
      system("#{gitlab_shell_user_home}/gitlab-shell/bin/gitlab-projects add-project #{name}.git")
    end

    # Import repository
    #
    # name - project path with namespace
    #
    # Ex.
    #   import_repository("gitlab/gitlab-ci", "https://github.com/randx/six.git")
    #
    def import_repository(name, url)
      system("#{gitlab_shell_user_home}/gitlab-shell/bin/gitlab-projects import-project #{name}.git #{url}")
    end

    # Remove repository from file system
    #
    # name - project path with namespace
    #
    # Ex.
    #   remove_repository("gitlab/gitlab-ci")
    #
    def remove_repository(name)
      system("#{gitlab_shell_user_home}/gitlab-shell/bin/gitlab-projects rm-project #{name}.git")
    end

    # Add new key to gitlab-shell
    #
    # Ex.
    #   add_key("key-42", "sha-rsa ...")
    #
    def add_key(key_id, key_content)
      system("#{gitlab_shell_user_home}/gitlab-shell/bin/gitlab-keys add-key #{key_id} \"#{key_content}\"")
    end

    # Remove ssh key from gitlab shell
    #
    # Ex.
    #   remove_key("key-342", "sha-rsa ...")
    #
    def remove_key(key_id, key_content)
      system("#{gitlab_shell_user_home}/gitlab-shell/bin/gitlab-keys rm-key #{key_id} \"#{key_content}\"")
    end

    def url_to_repo path
      Gitlab.config.gitlab_shell.ssh_path_prefix + "#{path}.git"
    end
   
    def gitlab_shell_user_home
      File.expand_path("~#{Gitlab.config.gitlab_shell.ssh_user}")
    end

  end
end
