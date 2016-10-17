require_relative 'base_service'

class CreateDeploymentService < BaseService
  def execute(deployable = nil)
    return unless executable?

    ActiveRecord::Base.transaction do
      @deployable = deployable
      @environment = environment
      @environment.external_url = expanded_url if expanded_url
      @environment.state_event = action
      @environment.save

      return if @environment.stopped?

      deploy.tap do |deployment|
        deployment.update_merge_request_metrics!
      end
    end
  end

  private

  def executable?
    project && name.present?
  end

  def deploy
    project.deployments.create(
      environment: @environment,
      ref: params[:ref],
      tag: params[:tag],
      sha: params[:sha],
      user: current_user,
      deployable: @deployable,
      on_stop: options.fetch(:on_stop, nil))
  end

  def environment
    @environment ||= project.environments.find_or_create_by(name: expanded_name)
  end

  def expanded_name
    ExpandVariables.expand(name, variables)
  end

  def expanded_url
    return unless url

    @expanded_url ||= ExpandVariables.expand(url, variables)
  end

  def name
    params[:environment]
  end

  def url
    options[:url]
  end

  def options
    params[:options] || {}
  end

  def variables
    params[:variables] || []
  end

  def action
    params[:options].fetch(:action, 'start')
  end
end
