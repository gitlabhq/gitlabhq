# frozen_string_literal: true

class Projects::Ci::LintsController < Projects::ApplicationController
  before_action :authorize_create_pipeline!

  def show
  end

  def create
    @content = params[:content]
    result   = Gitlab::Ci::YamlProcessor.new_with_validation_errors(@content, yaml_processor_options)

    @status = result.valid?
    @errors = result.errors

    if result.valid?
      @config_processor = result.content
      @stages = @config_processor.stages
      @builds = @config_processor.builds
      @jobs = @config_processor.jobs
    end

    render :show
  end

  private

  def yaml_processor_options
    {
      project: @project,
      user: current_user,
      sha: project.repository.commit.sha
    }
  end
end
