module Gitlab
  class Shell
    class Error < StandardError; end

    KeyAdder = Struct.new(:io) do
      def add_key(id, key)
        key.gsub!(/[[:space:]]+/, ' ').strip!
        io.puts("#{id}\t#{key}")
      end
    end

    class << self
      def version_required
        @version_required ||= File.read(Rails.root.
                                        join('GITLAB_SHELL_VERSION')).strip
      end
    end

    # Init new repository
    #
    # name - project path with namespace
    #
    # Ex.
    #   add_repository("gitlab/gitlab-ci")
    #
    def add_repository(name)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path,
                                   'add-project', "#{name}.git"])
    end

    # Import repository
    #
    # name - project path with namespace
    #
    # Ex.
    #   import_repository("gitlab/gitlab-ci", "https://github.com/randx/six.git")
    #
    def import_repository(name, url)
      output, status = Popen::popen([gitlab_shell_projects_path, 'import-project', "#{name}.git", url, '900'])
      raise Error, output unless status.zero?
      true
    end

    # Move repository
    #
    # path - project path with namespace
    # new_path - new project path with namespace
    #
    # Ex.
    #   mv_repository("gitlab/gitlab-ci", "randx/gitlab-ci-new")
    #
    def mv_repository(path, new_path)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path, 'mv-project',
                                   "#{path}.git", "#{new_path}.git"])
    end

    # Fork repository to new namespace
    #
    # path - project path with namespace
    # fork_namespace - namespace for forked project
    #
    # Ex.
    #  fork_repository("gitlab/gitlab-ci", "randx")
    #
    def fork_repository(path, fork_namespace)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path, 'fork-project',
                                   "#{path}.git", fork_namespace])
    end

    # Remove repository from file system
    #
    # name - project path with namespace
    #
    # Ex.
    #   remove_repository("gitlab/gitlab-ci")
    #
    def remove_repository(name)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path,
                                   'rm-project', "#{name}.git"])
    end

    # Gc repository
    #
    # path - project path with namespace
    #
    # Ex.
    #   gc("gitlab/gitlab-ci")
    #
    def gc(path)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path, 'gc',
                                   "#{path}.git"])
    end

    # Add new key to gitlab-shell
    #
    # Ex.
    #   add_key("key-42", "sha-rsa ...")
    #
    def add_key(key_id, key_content)
      Gitlab::Utils.system_silent([gitlab_shell_keys_path,
                                   'add-key', key_id, key_content])
    end

    # Batch-add keys to authorized_keys
    #
    # Ex.
    #   batch_add_keys { |adder| adder.add_key("key-42", "sha-rsa ...") }
    def batch_add_keys(&block)
      IO.popen(%W(#{gitlab_shell_path}/bin/gitlab-keys batch-add-keys), 'w') do |io|
        block.call(KeyAdder.new(io))
      end
    end

    # Remove ssh key from gitlab shell
    #
    # Ex.
    #   remove_key("key-342", "sha-rsa ...")
    #
    def remove_key(key_id, key_content)
      Gitlab::Utils.system_silent([gitlab_shell_keys_path,
                                   'rm-key', key_id, key_content])
    end

    # Remove all ssh keys from gitlab shell
    #
    # Ex.
    #   remove_all_keys
    #
    def remove_all_keys
      Gitlab::Utils.system_silent([gitlab_shell_keys_path, 'clear'])
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

    def url_to_repo(path)
      Gitlab.config.gitlab_shell.ssh_path_prefix + "#{path}.git"
    end

    # Return GitLab shell version
    def version
      gitlab_shell_version_file = "#{gitlab_shell_path}/VERSION"

      if File.readable?(gitlab_shell_version_file)
        File.read(gitlab_shell_version_file).chomp
      end
    end

    # Check if such directory exists in repositories.
    #
    # Usage:
    #   exists?('gitlab')
    #   exists?('gitlab/cookies.git')
    #
    def exists?(dir_name)
      File.exist?(full_path(dir_name))
    end

    protected

    def gitlab_shell_path
      Gitlab.config.gitlab_shell.path
    end

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

    def gitlab_shell_projects_path
      File.join(gitlab_shell_path, 'bin', 'gitlab-projects')
    end

    def gitlab_shell_keys_path
      File.join(gitlab_shell_path, 'bin', 'gitlab-keys')
    end
  end
end
