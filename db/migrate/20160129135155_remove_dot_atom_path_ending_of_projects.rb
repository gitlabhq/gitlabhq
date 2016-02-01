class RemoveDotAtomPathEndingOfProjects < ActiveRecord::Migration
  include Gitlab::ShellAdapter

  class ProjectPath
    attr_reader :old_path, :id

    def initialize(old_path, id)
      @old_path = old_path
      @id = id
    end

    def clean_path
      @_clean_path ||= PathCleaner.clean(@old_path)
    end
  end

  class PathCleaner
    def initialize(path)
      @path = path
    end

    def self.clean(*args)
      new(*args).clean
    end

    def clean
      path = cleaned_path
      count = 0
      while path_exists?(path)
        path = "#{cleaned_path}#{count}"
        count += 1
      end
      path
    end

    def cleaned_path
      @_cleaned_path ||= @path.gsub(/\.atom\z/, '-atom')
    end

    def path_exists?(path)
      Project.find_by_path(path)
    end
  end

  def projects_with_dot_atom
    select_all("SELECT id, path FROM projects WHERE lower(path) LIKE '%.atom'")
  end

  def up
    projects_with_dot_atom.each do |project|
      binding.pry
      project_path = ProjectPath.new(project['path'], project['id'])
      clean_path(project_path) if move_path(project_path)
    end
  end

  private

  def clean_path(project_path)
    execute "UPDATE projects SET path = '#{project_path.clean_path}' WHERE id = #{project.id}"
  end

  def move_path(project_path)
    # Based on RemovePeriodsAtEndsOfUsernames
    # Don't attempt to move if original path only contains periods.
    return if project_path.clean_path =~ /\A\.+\z/
    if gitlab_shell.mv_namespace(project_path.old_path, project_path.clean_path)
      # If repositories moved successfully we need to remove old satellites
      # and send update instructions to users.
      # However we cannot allow rollback since we moved namespace dir
      # So we basically we mute exceptions in next actions
      begin
        gitlab_shell.rm_satellites(project_path.old_path)
          # We cannot send update instructions since models and mailers
          # can't safely be used from migrations as they may be written for
          # later versions of the database.
          # send_update_instructions
      rescue
        # Returning false does not rollback after_* transaction but gives
        # us information about failing some of tasks
        false
      end
    else
      # if we cannot move namespace directory we should avoid
      # db changes in order to prevent out of sync between db and fs
      false
    end
  end
end
