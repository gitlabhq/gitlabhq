# frozen_string_literal: true

class StopEnvironmentService
  attr_reader :deployment

  delegate :environment, to: :deployment

  def initialize(deployment)
    @deployment = deployment
  end

  def execute
    return unless deployment.stopped?

    environment.fire_state_event(:stop)
    environment.expire_etag_cache
  end
end
