module Gitlab
  class Shell
    class AccessDenied < StandardError; end

    class KeyAdder < Struct.new(:io)
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
      Gitlab::Utils.system_silent([gitlab_shell_projects_path, 'import-project',
                                   "#{name}.git", url, '240'])
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
      Gitlab::Utils.system_silent([gitlab_shell_projects_path, 'mv-project',
                                   "#{path}.git", "#{new_path}.git"])
    end

    # Update HEAD for repository
    #
    # path - project path with namespace
    # branch - repository branch name
    #
    # Ex.
    #  update_repository_head("gitlab/gitlab-ci", "3-1-stable")
    #
    def update_repository_head(path, branch)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path, 'update-head',
                                   "#{path}.git", branch])
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

    # Add repository branch from passed ref
    #
    # path - project path with namespace
    # branch_name - new branch name
    # ref - HEAD for new branch
    #
    # Ex.
    #   add_branch("gitlab/gitlab-ci", "4-0-stable", "master")
    #
    def add_branch(path, branch_name, ref)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path, 'create-branch',
                                   "#{path}.git", branch_name, ref])
    end

    # Remove repository branch
    #
    # path - project path with namespace
    # branch_name - branch name to remove
    #
    # Ex.
    #   rm_branch("gitlab/gitlab-ci", "4-0-stable")
    #
    def rm_branch(path, branch_name)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path, 'rm-branch',
                                   "#{path}.git", branch_name])
    end

    # Add repository tag from passed ref
    #
    # path - project path with namespace
    # tag_name - new tag name
    # ref - HEAD for new tag
    # message - optional message for tag (annotated tag)
    #
    # Ex.
    #   add_tag("gitlab/gitlab-ci", "v4.0", "master")
    #   add_tag("gitlab/gitlab-ci", "v4.0", "master", "message")
    #
    def add_tag(path, tag_name, ref, message = nil)
      cmd = %W(#{gitlab_shell_path}/bin/gitlab-projects create-tag #{path}.git
               #{tag_name} #{ref})
      cmd << message unless message.nil? || message.empty?
      Gitlab::Utils.system_silent(cmd)
    end

    # Remove repository tag
    #
    # path - project path with namespace
    # tag_name - tag name to remove
    #
    # Ex.
    #   rm_tag("gitlab/gitlab-ci", "v4.0")
    #
    def rm_tag(path, tag_name)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path, 'rm-tag',
                                   "#{path}.git", tag_name])
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
      File.exists?(full_path(dir_name))
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
