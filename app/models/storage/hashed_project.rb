module Storage
  class HashedProject
    attr_accessor :project
    delegate :gitlab_shell, :repository_storage_path, to: :project

    ROOT_PATH_PREFIX = '@hashed'.freeze

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

    private

    # Generates the hash for the project path and name on disk
    # If you need to refer to the repository on disk, use the `#disk_path`
    def disk_hash
      @disk_hash ||= Digest::SHA2.hexdigest(project.id.to_s) if project.id
    end
  end
end
