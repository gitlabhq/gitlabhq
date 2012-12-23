# ProjectMover class
#
# Used for moving project repositories from one subdir to another
module Gitlab
  class ProjectMover
    class ProjectMoveError < StandardError; end

    attr_reader :project, :old_dir, :new_dir

    def initialize(project, old_dir, new_dir)
      @project = project
      @old_dir = old_dir
      @new_dir = new_dir
    end

    def execute
      # Create new dir if missing
      new_dir_path = File.join(Gitlab.config.gitolite.repos_path, new_dir)
      system("mkdir -m 770 #{new_dir_path}") unless File.exists?(new_dir_path)

      old_path = File.join(Gitlab.config.gitolite.repos_path, old_dir, "#{project.path}.git")
      new_path = File.join(new_dir_path, "#{project.path}.git")

      if File.exists? new_path
        raise ProjectMoveError.new("Destination #{new_path} already exists")
      end

      if system("mv #{old_path} #{new_path}")
        log_info "Project #{project.name} was moved from #{old_path} to #{new_path}"
        true
      else
        message = "Project #{project.name} cannot be moved from #{old_path} to #{new_path}"
        log_info "Error! #{message}"
        raise ProjectMoveError.new(message)
      end
    end

    protected

    def log_info message
      Gitlab::AppLogger.info message
    end
  end
end
