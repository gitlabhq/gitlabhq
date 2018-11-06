# frozen_string_literal: true

class StartEnvironmentService
  attr_reader :deployment
  attr_reader :deployable

  delegate :environment, to: :deployment
  delegate :variables, to: :deployable

  def initialize(deployment)
    @deployment = deployment
    @deployable = deployment.deployable
  end

  def execute
    return unless deployment.deployed?

    deployment.create_ref
    deployment.invalidate_cache

    ActiveRecord::Base.transaction do
      environment.external_url = expanded_environment_url if
        expanded_environment_url

      environment.fire_state_event(:start)

      break unless environment.save

      deployment.tap(&:update_merge_request_metrics!)
    end
  end

  private

  def environment_options
    @environment_options ||= deployable.options&.dig(:environment) || {}
  end

  def expanded_environment_url
    return @expanded_environment_url if defined?(@expanded_environment_url)
    return unless environment_url

    @expanded_environment_url =
      ExpandVariables.expand(environment_url, variables)
  end

  def environment_url
    environment_options[:url]
  end
end
