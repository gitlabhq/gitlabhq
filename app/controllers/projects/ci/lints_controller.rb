class Projects::Ci::LintsController < Projects::ApplicationController
  before_action :ensure_user_access

  def show
  end

  def create
    @content = params[:content]
    @error = Gitlab::Ci::YamlProcessor.validation_message(@content,  yaml_processor_options)
    @status = @error.blank?

    if @error.blank?
      @config_processor = Gitlab::Ci::YamlProcessor.new(@content, yaml_processor_options)
      @stages = @config_processor.stages
      @builds = @config_processor.builds
      @jobs = @config_processor.jobs
    end

    render :show
  end

  private

  def yaml_processor_options
    { project: @project, sha: project.repository.commit.sha }
  end

  def ensure_user_access
    return access_denied! unless can?(current_user, :create_pipeline, @project)
  end
end
