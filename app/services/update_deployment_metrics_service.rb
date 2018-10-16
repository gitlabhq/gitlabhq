# frozen_string_literal: true

class UpdateDeploymentMetricsService
  attr_reader :job

  delegate :expanded_environment_name,
           :variables,
           :project,
           to: :job

  def initialize(job)
    @job = job
  end

  def execute
    return unless executable?

    ActiveRecord::Base.transaction do
      environment.external_url = expanded_environment_url if
        expanded_environment_url

      environment.fire_state_event(action)

      break unless environment.save
      break if environment.stopped?

      deploy.tap(&:update_merge_request_metrics!)
    end
  end

  private

  def executable?
    project && job.environment.present? && environment
  end

  def deploy
    job.last_deployment
  end

  def environment
    @environment ||= job.persisted_environment
  end

  def environment_options
    @environment_options ||= job.options&.dig(:environment) || {}
  end

  def expanded_environment_url
    return @expanded_environment_url if defined?(@expanded_environment_url)

    @expanded_environment_url =
      ExpandVariables.expand(environment_url, variables) if environment_url
  end

  def environment_url
    environment_options[:url]
  end

  def action
    environment_options[:action] || 'start'
  end
end
