module Geo
  RepositoryCannotBeRenamed = Class.new(StandardError)

  class MoveRepositoryService
    include Gitlab::ShellAdapter
    include Gitlab::Geo::ProjectLogHelpers

    attr_reader :project, :old_disk_path, :new_disk_path

    def initialize(project, old_disk_path, new_disk_path)
      @project = project
      @old_disk_path = old_disk_path
      @new_disk_path = new_disk_path
    end

    def execute
      project.ensure_storage_path_exists
      move_project_repository && move_wiki_repository
    rescue
      log_error('Repository cannot be renamed')
      false
    end

    private

    def move_project_repository
      gitlab_shell.mv_repository(project.repository_storage_path, old_disk_path, new_disk_path)
    end

    def move_wiki_repository
      gitlab_shell.mv_repository(project.repository_storage_path, "#{old_disk_path}.wiki", "#{new_disk_path}.wiki")
    end
  end
end
