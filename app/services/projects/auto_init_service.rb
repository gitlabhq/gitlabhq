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
      if !project.auto_init_from_template?
        init_from_template = "false"
      else
        init_from_template = "true"
      end

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

  end
end