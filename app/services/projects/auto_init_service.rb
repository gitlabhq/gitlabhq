module Projects
  class AutoInitService < BaseService

    attr_accessor :project, :project_init_dir, :config_auto_init_template_dir

    def initialize(project)
      @project = project
      @project_init_dir = File.join(
        File.expand_path(Rails.root),
        'tmp',
        'gitlab-autoinit-template',
        project.path_with_namespace
      )
      @config_auto_init_template_dir = Gitlab.config.gitlab.auto_init_template_dir
    end

    def execute
      if !exists(config_auto_init_template_dir) || !has_files(config_auto_init_template_dir)
        init_from_template = "false"
      else
        init_from_template = "true"
      end

      Gitlab::AppLogger.info("init_from_template = #{init_from_template}")

      GitlabShellWorker.perform_in(
        1.seconds,
        :init_repository,
        project.path_with_namespace,
        project_init_dir,
        init_from_template,
        config_auto_init_template_dir,
        project.owner.name,
        project.owner.email
      )
    end

    def exists(directory)
      File.directory?(directory)
    end

    def has_files(directory)
      if exists(directory)
        Dir.entries("#{directory}").size > 2
      else
        false
      end
    end

  end
end