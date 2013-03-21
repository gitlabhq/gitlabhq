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

    # Move repository
    #
    # path - project path with namespace
    # new_path - new project path with namespace
    #
    # Ex.
    #   mv_repository("gitlab/gitlab-ci", "randx/gitlab-ci-new.git")
    #
    def mv_repository(path, new_path)
      system("#{gitlab_shell_user_home}/gitlab-shell/bin/gitlab-projects mv-project #{path}.git #{new_path}.git")
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

    # Add empty directory for storing repositories
    #
    # Ex.
    #   add_namespace("gitlab")
    #
    def add_namespace(name)
      FileUtils.mkdir(full_path(name), mode: 0770) unless exists?(name)
    end

    # Remove directory from repositories storage
    # Every repository inside this directory will be removed too
    #
    # Ex.
    #   rm_namespace("gitlab")
    #
    def rm_namespace(name)
      FileUtils.rm_r(full_path(name), force: true)
    end

    # Move namespace directory inside repositories storage
    #
    # Ex.
    #   mv_namespace("gitlab", "gitlabhq")
    #
    def mv_namespace(old_name, new_name)
      return false if exists?(new_name) || !exists?(old_name)

      FileUtils.mv(full_path(old_name), full_path(new_name))
    end

    # Remove GitLab Satellites for provided path (namespace or repo dir)
    #
    # Ex.
    #   rm_satellites("gitlab")
    #
    #   rm_satellites("gitlab/gitlab-ci.git")
    #
    def rm_satellites(path)
      raise ArgumentError.new("Path can't be blank") if path.blank?

      satellites_path = File.join(Gitlab.config.satellites.path, path)
      FileUtils.rm_r(satellites_path, force: true)
    end

    def url_to_repo path
      Gitlab.config.gitlab_shell.ssh_path_prefix + "#{path}.git"
    end

    protected

    def gitlab_shell_user_home
      File.expand_path("~#{Gitlab.config.gitlab_shell.ssh_user}")
    end

    def repos_path
      Gitlab.config.gitlab_shell.repos_path
    end

    def full_path(dir_name)
      raise ArgumentError.new("Directory name can't be blank") if dir_name.blank?

      File.join(repos_path, dir_name)
    end

    def exists?(dir_name)
      File.exists?(full_path(dir_name))
    end
  end
end
