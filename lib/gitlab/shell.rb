# frozen_string_literal: true

require 'securerandom'

module Gitlab
  # This class is an artifact of a time when common repository operations were
  # performed by calling out to scripts in the gitlab-shell project. Now, these
  # operations are all performed by Gitaly, and are mostly accessible through
  # the Repository class. Prefer using a Repository to functionality here.
  #
  # Legacy code relating to namespaces still relies on Gitlab::Shell; it can be
  # converted to a module once https://gitlab.com/groups/gitlab-org/-/epics/2320
  # is completed. https://gitlab.com/gitlab-org/gitlab/-/issues/25095 tracks it.
  class Shell
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

      # Return GitLab shell version
      #
      # @return [String] version
      def version
        @version ||= File.read(gitlab_shell_version_file).chomp if File.readable?(gitlab_shell_version_file)
      end

      private

      def gitlab_shell_path
        File.expand_path(Gitlab.config.gitlab_shell.path)
      end

      def gitlab_shell_version_file
        File.join(gitlab_shell_path, 'VERSION')
      end

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

    # Move or rename a repository
    #
    # @example Move/rename a repository
    #   mv_repository("/path/to/storage", "gitlab/gitlab-ci", "randx/gitlab-ci-new")
    #
    # @param [String] storage project's storage path
    # @param [String] disk_path current project path on disk
    # @param [String] new_disk_path new project path on disk
    # @return [Boolean] whether repository could be moved/renamed on disk
    #
    # @deprecated
    def mv_repository(storage, disk_path, new_disk_path)
      return false if disk_path.empty? || new_disk_path.empty?

      Gitlab::Git::Repository.new(storage, "#{disk_path}.git", nil, nil).rename("#{new_disk_path}.git")

      true
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, path: disk_path, new_path: new_disk_path, storage: storage)

      false
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
    #
    # @deprecated
    def remove_repository(storage, disk_path)
      return false if disk_path.empty?

      Gitlab::Git::Repository.new(storage, "#{disk_path}.git", nil, nil).remove

      true
    rescue StandardError => e
      Gitlab::AppLogger.warn("Repository does not exist: #{e} at: #{disk_path}.git")
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
    #
    # @deprecated
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
    #
    # @deprecated
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
    #
    # @deprecated
    def mv_namespace(storage, old_name, new_name)
      Gitlab::GitalyClient::NamespaceService.new(storage).rename(old_name, new_name)
    rescue GRPC::InvalidArgument => e
      Gitlab::ErrorTracking.track_exception(e, old_name: old_name, new_name: new_name, storage: storage)

      false
    end

    # Check if repository exists on disk
    #
    # @example Check if repository exists
    #   repository_exists?('default', 'gitlab-org/gitlab.git')
    #
    # @return [Boolean] whether repository exists or not
    # @param [String] storage project's storage path
    # @param [Object] dir_name repository dir name
    #
    # @deprecated
    def repository_exists?(storage, dir_name)
      Gitlab::Git::Repository.new(storage, dir_name, nil, nil).exists?
    rescue GRPC::Internal
      false
    end
  end
end
