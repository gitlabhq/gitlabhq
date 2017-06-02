class CreateDeploymentService
  attr_reader :job

  delegate :expanded_environment_name,
           :environment_url,
           :project,
           to: :job

  def initialize(job)
    @job = job
  end

  def execute
    return unless executable?

    ActiveRecord::Base.transaction do
      environment.external_url = environment_url if environment_url
      environment.fire_state_event(action)

      return unless environment.save
      return if environment.stopped?

      deploy.tap(&:update_merge_request_metrics!)
    end
  end

  private

  def executable?
    project && job.environment.present? && environment
  end

  def deploy
    project.deployments.create(
      environment: environment,
      ref: job.ref,
      tag: job.tag,
      sha: job.sha,
      user: job.user,
      deployable: job,
      on_stop: on_stop)
  end

  def environment
    @environment ||= job.persisted_environment
  end

  def environment_options
    @environment_options ||= job.options&.dig(:environment) || {}
  end

  def on_stop
    environment_options[:on_stop]
  end

  def action
    environment_options[:action] || 'start'
  end
end
