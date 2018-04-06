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
      unless move_repositories!
        return false
      end

      unless project.hashed_storage?(:attachments)
        Geo::FilesExpireService.new(project, old_disk_path).execute
      end

      true
    end

    private

    def move_repositories!
      project.ensure_storage_path_exists

      unless move_project_repository
        log_error('Repository cannot be moved')
        return false
      end

      # We try to move the wiki repo despite the fact the wiki enabled or not
      # But we consider the move as failed, only if the wiki is enabled
      # If the wiki is disabled but repository exists we need to move it anyway as it
      # can be acquired by the different project if later someone will take the same name.
      # Once we have hashed storage as the only option this problem will be eliminated
      if !move_wiki_repository && project.wiki_enabled?
        log_error('Wiki repository cannot be moved')
        return false
      end

      true
    rescue => ex
      log_error('Repository cannot be moved', error: ex)
      false
    end

    def move_project_repository
      gitlab_shell.mv_repository(project.repository_storage_path, old_disk_path, new_disk_path)
    end

    def move_wiki_repository
      gitlab_shell.mv_repository(project.repository_storage_path, "#{old_disk_path}.wiki", "#{new_disk_path}.wiki")
    end
  end
end
