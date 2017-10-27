module Storage
  class HashedProject
    attr_accessor :project
    delegate :gitlab_shell, :repository_storage_path, to: :project

    ROOT_PATH_PREFIX = '@hashed'.freeze
    STORAGE_VERSION = 1

    def initialize(project)
      @project = project
    end

    # Base directory
    #
    # @return [String] directory where repository is stored
    def base_dir
      "#{ROOT_PATH_PREFIX}/#{disk_hash[0..1]}/#{disk_hash[2..3]}" if disk_hash
    end

    # Disk path is used to build repository and project's wiki path on disk
    #
    # @return [String] combination of base_dir and the repository own name without `.git` or `.wiki.git` extensions
    def disk_path
      "#{base_dir}/#{disk_hash}" if disk_hash
    end

    def ensure_storage_path_exists
      gitlab_shell.add_namespace(repository_storage_path, base_dir)
    end

    def rename_repo
      true
    end

    def after_rename_repo
      path_before_change = project.previous_changes['path'].first

      # We need to check if project had been rolled out to move resource to hashed storage or not and decide
      # if we need execute any take action or no-op.

      unless project.storage_version >= 2
        Gitlab::UploadsTransfer.new.rename_project(path_before_change, project.path, project.namespace.full_path)
      end

      Gitlab::PagesTransfer.new.rename_project(path_before_change, project.path, project.namespace.full_path)
    end

    private

    # Generates the hash for the project path and name on disk
    # If you need to refer to the repository on disk, use the `#disk_path`
    def disk_hash
      @disk_hash ||= Digest::SHA2.hexdigest(project.id.to_s) if project.id
    end
  end
end
