module Geo
  class MoveRepositoryService
    include Gitlab::ShellAdapter

    attr_reader :id, :name, :old_path_with_namespace, :new_path_with_namespace

    def initialize(id, name, old_path_with_namespace, new_path_with_namespace)
      @id = id
      @name = name
      @old_path_with_namespace = old_path_with_namespace
      @new_path_with_namespace = new_path_with_namespace
    end

    def execute
      project = Project.find(id)
      project.expire_caches_before_rename(old_path_with_namespace)

      # Make sure target directory exists (used when transfering repositories)
      project.namespace.ensure_dir_exist

      if gitlab_shell.mv_repository(old_path_with_namespace, new_path_with_namespace)
        # If repository moved successfully we need to send update instructions to users.
        # However we cannot allow rollback since we moved repository
        # So we basically we mute exceptions in next actions
        begin
          gitlab_shell.mv_repository("#{old_path_with_namespace}.wiki", "#{new_path_with_namespace}.wiki")
        rescue
          # Returning false does not rollback after_* transaction but gives
          # us information about failing some of tasks
          false
        end
      else
        # if we cannot move namespace directory we should rollback
        # db changes in order to prevent out of sync between db and fs
        raise Exception.new('repository cannot be renamed')
      end
    end
  end
end
