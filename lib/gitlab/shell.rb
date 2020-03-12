# frozen_string_literal: true

# Gitaly note: SSH key operations are not part of Gitaly so will never be migrated.

require 'securerandom'

module Gitlab
  class Shell
    GITLAB_SHELL_ENV_VARS = %w(GIT_TERMINAL_PROMPT).freeze

    Error = Class.new(StandardError)

    class << self
      # Retrieve GitLab Shell secret token
      #
      # @return [String] secret token
      def secret_token
        @secret_token ||= begin
          File.read(Gitlab.config.gitlab_shell.secret_file).chomp
        end
      end

      # Ensure gitlab shell has a secret token stored in the secret_file
      # if that was never generated, generate a new one
      def ensure_secret_token!
        return if File.exist?(File.join(Gitlab.config.gitlab_shell.path, '.gitlab_shell_secret'))

        generate_and_link_secret_token
      end

      # Returns required GitLab shell version
      #
      # @return [String] version from the manifest file
      def version_required
        @version_required ||= File.read(Rails.root
                                        .join('GITLAB_SHELL_VERSION')).strip
      end

      private

      # Create (if necessary) and link the secret token file
      def generate_and_link_secret_token
        secret_file = Gitlab.config.gitlab_shell.secret_file
        shell_path = Gitlab.config.gitlab_shell.path

        unless File.size?(secret_file)
          # Generate a new token of 16 random hexadecimal characters and store it in secret_file.
          @secret_token = SecureRandom.hex(16)
          File.write(secret_file, @secret_token)
        end

        link_path = File.join(shell_path, '.gitlab_shell_secret')
        if File.exist?(shell_path) && !File.exist?(link_path)
          FileUtils.symlink(secret_file, link_path)
        end
      end
    end

    # Initialize a new project repository using a Project model
    #
    # @param [Project] project
    # @return [Boolean] whether repository could be created
    def create_project_repository(project)
      create_repository(project.repository_storage, project.disk_path, project.full_path)
    end

    # Initialize a new wiki repository using a Project model
    #
    # @param [Project] project
    # @return [Boolean] whether repository could be created
    def create_wiki_repository(project)
      create_repository(project.repository_storage, project.wiki.disk_path, project.wiki.full_path)
    end

    # Init new repository
    #
    # @example Create a repository
    #   create_repository("default", "path/to/gitlab-ci", "gitlab/gitlab-ci")
    #
    # @param [String] storage the shard key
    # @param [String] disk_path project path on disk
    # @param [String] gl_project_path project name
    # @return [Boolean] whether repository could be created
    def create_repository(storage, disk_path, gl_project_path)
      relative_path = disk_path.dup
      relative_path << '.git' unless relative_path.end_with?('.git')

      # During creation of a repository, gl_repository may not be known
      # because that depends on a yet-to-be assigned project ID in the
      # database (e.g. project-1234), so for now it is blank.
      repository = Gitlab::Git::Repository.new(storage, relative_path, '', gl_project_path)
      wrapped_gitaly_errors { repository.gitaly_repository_client.create_repository }

      true
    rescue => err # Once the Rugged codes gets removes this can be improved
      Rails.logger.error("Failed to add repository #{storage}/#{disk_path}: #{err}") # rubocop:disable Gitlab/RailsLogger
      false
    end

    # Import wiki repository from external service
    #
    # @param [Project] project
    # @param [Gitlab::LegacyGithubImport::WikiFormatter, Gitlab::BitbucketImport::WikiFormatter] wiki_formatter
    # @return [Boolean] whether repository could be imported
    def import_wiki_repository(project, wiki_formatter)
      import_repository(project.repository_storage, wiki_formatter.disk_path, wiki_formatter.import_url, project.wiki.full_path)
    end

    # Import project repository from external service
    #
    # @param [Project] project
    # @return [Boolean] whether repository could be imported
    def import_project_repository(project)
      import_repository(project.repository_storage, project.disk_path, project.import_url, project.full_path)
    end

    # Import repository
    #
    # @example Import a repository
    #   import_repository("nfs-file06", "gitlab/gitlab-ci", "https://gitlab.com/gitlab-org/gitlab-test.git", "gitlab/gitlab-ci")
    #
    # @param [String] storage  project's storage name
    # @param [String] disk_path project path on disk
    # @param [String] url from external resource to import from
    # @param [String] gl_project_path project name
    # @return [Boolean] whether repository could be imported
    def import_repository(storage, disk_path, url, gl_project_path)
      if url.start_with?('.', '/')
        raise Error.new("don't use disk paths with import_repository: #{url.inspect}")
      end

      relative_path = "#{disk_path}.git"
      cmd = GitalyGitlabProjects.new(storage, relative_path, gl_project_path)

      success = cmd.import_project(url, git_timeout)
      raise Error, cmd.output unless success

      success
    end

    # Move or rename a repository
    #
    # @example Move/rename a repository
    #   mv_repository("/path/to/storage", "gitlab/gitlab-ci", "randx/gitlab-ci-new")
    #
    # @param [String] storage project's storage path
    # @param [String] disk_path current project path on disk
    # @param [String] new_disk_path new project path on disk
    # @return [Boolean] whether repository could be moved/renamed on disk
    def mv_repository(storage, disk_path, new_disk_path)
      return false if disk_path.empty? || new_disk_path.empty?

      Gitlab::Git::Repository.new(storage, "#{disk_path}.git", nil, nil).rename("#{new_disk_path}.git")

      true
    rescue => e
      Gitlab::ErrorTracking.track_exception(e, path: disk_path, new_path: new_disk_path, storage: storage)

      false
    end

    # Fork repository to new path
    #
    # @param [Project] source_project forked-from Project
    # @param [Project] target_project forked-to Project
    def fork_repository(source_project, target_project)
      forked_from_relative_path = "#{source_project.disk_path}.git"
      fork_args = [target_project.repository_storage, "#{target_project.disk_path}.git", target_project.full_path]

      GitalyGitlabProjects.new(source_project.repository_storage, forked_from_relative_path, source_project.full_path).fork_repository(*fork_args)
    end

    # Removes a repository from file system, using rm_diretory which is an alias
    # for rm_namespace. Given the underlying implementation removes the name
    # passed as second argument on the passed storage.
    #
    # @example Remove a repository
    #   remove_repository("/path/to/storage", "gitlab/gitlab-ci")
    #
    # @param [String] storage project's storage path
    # @param [String] disk_path current project path on disk
    def remove_repository(storage, disk_path)
      return false if disk_path.empty?

      Gitlab::Git::Repository.new(storage, "#{disk_path}.git", nil, nil).remove

      true
    rescue => e
      Rails.logger.warn("Repository does not exist: #{e} at: #{disk_path}.git") # rubocop:disable Gitlab/RailsLogger
      Gitlab::ErrorTracking.track_exception(e, path: disk_path, storage: storage)

      false
    end

    # Add empty directory for storing repositories
    #
    # @example Add new namespace directory
    #   add_namespace("default", "gitlab")
    #
    # @param [String] storage project's storage path
    # @param [String] name namespace name
    def add_namespace(storage, name)
      Gitlab::GitalyClient.allow_n_plus_1_calls do
        Gitlab::GitalyClient::NamespaceService.new(storage).add(name)
      end
    rescue GRPC::InvalidArgument => e
      raise ArgumentError, e.message
    end

    # Remove directory from repositories storage
    # Every repository inside this directory will be removed too
    #
    # @example Remove namespace directory
    #   rm_namespace("default", "gitlab")
    #
    # @param [String] storage project's storage path
    # @param [String] name namespace name
    def rm_namespace(storage, name)
      Gitlab::GitalyClient::NamespaceService.new(storage).remove(name)
    rescue GRPC::InvalidArgument => e
      raise ArgumentError, e.message
    end
    alias_method :rm_directory, :rm_namespace

    # Move namespace directory inside repositories storage
    #
    # @example Move/rename a namespace directory
    #   mv_namespace("/path/to/storage", "gitlab", "gitlabhq")
    #
    # @param [String] storage project's storage path
    # @param [String] old_name current namespace name
    # @param [String] new_name new namespace name
    def mv_namespace(storage, old_name, new_name)
      Gitlab::GitalyClient::NamespaceService.new(storage).rename(old_name, new_name)
    rescue GRPC::InvalidArgument => e
      Gitlab::ErrorTracking.track_exception(e, old_name: old_name, new_name: new_name, storage: storage)

      false
    end

    # Return a SSH url for a given project path
    #
    # @param [String] full_path project path (URL)
    # @return [String] SSH URL
    def url_to_repo(full_path)
      Gitlab.config.gitlab_shell.ssh_path_prefix + "#{full_path}.git"
    end

    # Return GitLab shell version
    #
    # @return [String] version
    def version
      gitlab_shell_version_file = "#{gitlab_shell_path}/VERSION"

      if File.readable?(gitlab_shell_version_file)
        File.read(gitlab_shell_version_file).chomp
      end
    end

    # Check if repository exists on disk
    #
    # @example Check if repository exists
    #   repository_exists?('default', 'gitlab-org/gitlab.git')
    #
    # @return [Boolean] whether repository exists or not
    # @param [String] storage project's storage path
    # @param [Object] dir_name repository dir name
    def repository_exists?(storage, dir_name)
      Gitlab::Git::Repository.new(storage, dir_name, nil, nil).exists?
    rescue GRPC::Internal
      false
    end

    # Return hooks folder path used by projects
    #
    # @return [String] path
    def hooks_path
      File.join(gitlab_shell_path, 'hooks')
    end

    protected

    def gitlab_shell_path
      File.expand_path(Gitlab.config.gitlab_shell.path)
    end

    def gitlab_shell_user_home
      File.expand_path("~#{Gitlab.config.gitlab_shell.ssh_user}")
    end

    def full_path(storage, dir_name)
      raise ArgumentError.new("Directory name can't be blank") if dir_name.blank?

      File.join(Gitlab.config.repositories.storages[storage].legacy_disk_path, dir_name)
    end

    private

    def git_timeout
      Gitlab.config.gitlab_shell.git_timeout
    end

    def wrapped_gitaly_errors
      yield
    rescue GRPC::NotFound, GRPC::BadStatus => e
      # Old Popen code returns [Error, output] to the caller, so we
      # need to do the same here...
      raise Error, e
    end

    class GitalyGitlabProjects
      attr_reader :shard_name, :repository_relative_path, :output, :gl_project_path

      def initialize(shard_name, repository_relative_path, gl_project_path)
        @shard_name = shard_name
        @repository_relative_path = repository_relative_path
        @output = ''
        @gl_project_path = gl_project_path
      end

      def import_project(source, _timeout)
        raw_repository = Gitlab::Git::Repository.new(shard_name, repository_relative_path, nil, gl_project_path)

        Gitlab::GitalyClient::RepositoryService.new(raw_repository).import_repository(source)
        true
      rescue GRPC::BadStatus => e
        @output = e.message
        false
      end

      def fork_repository(new_shard_name, new_repository_relative_path, new_project_name)
        target_repository = Gitlab::Git::Repository.new(new_shard_name, new_repository_relative_path, nil, new_project_name)
        raw_repository = Gitlab::Git::Repository.new(shard_name, repository_relative_path, nil, gl_project_path)

        Gitlab::GitalyClient::RepositoryService.new(target_repository).fork_repository(raw_repository)
      rescue GRPC::BadStatus => e
        logger.error "fork-repository failed: #{e.message}"
        false
      end

      def logger
        Rails.logger # rubocop:disable Gitlab/RailsLogger
      end
    end
  end
end
