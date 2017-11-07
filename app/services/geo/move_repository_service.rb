module Geo
  class MoveRepositoryService
    include Gitlab::ShellAdapter

    attr_reader :project, :old_disk_path, :new_disk_path

    def initialize(project, old_disk_path, new_disk_path)
      @project = project
      @old_disk_path = old_disk_path
      @new_disk_path = new_disk_path
    end

    def execute
      # Make sure target directory exists (used when transfering repositories)
      project.ensure_storage_path_exists

      if gitlab_shell.mv_repository(project.repository_storage_path,
                                    old_disk_path, new_disk_path)
        # If repository moved successfully we need to send update instructions to users.
        # However we cannot allow rollback since we moved repository
        # So we basically we mute exceptions in next actions
        begin
          gitlab_shell.mv_repository(project.repository_storage_path,
                                     "#{old_disk_path}.wiki", "#{new_disk_path}.wiki")
        rescue
          # Returning false does not rollback after_* transaction but gives
          # us information about failing some of tasks
          false
        end
      else
        # if we cannot move namespace directory we should rollback
        # db changes in order to prevent out of sync between db and fs
        raise StandardError.new('Repository cannot be renamed')
      end

      true
    end
  end
end
