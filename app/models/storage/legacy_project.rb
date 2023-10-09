# frozen_string_literal: true

module Storage
  class LegacyProject
    attr_accessor :project

    delegate :namespace, :gitlab_shell, :repository_storage, to: :project

    def initialize(project)
      @project = project
    end

    # Base directory
    #
    # @return [String] directory where repository is stored
    def base_dir
      namespace.full_path
    end

    # Disk path is used to build repository and project's wiki path on disk
    #
    # @return [String] combination of base_dir and the repository own name without `.git` or `.wiki.git` extensions
    def disk_path
      project.full_path
    end
  end
end
