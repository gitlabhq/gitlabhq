# frozen_string_literal: true

class EnvironmentStatus
  attr_reader :environment, :merge_request

  delegate :id, to: :environment
  delegate :name, to: :environment
  delegate :project, to: :environment
  delegate :deployed_at, to: :deployment, allow_nil: true

  def initialize(environment, merge_request)
    @environment = environment
    @merge_request = merge_request
  end

  def deployment
    @deployment ||= environment.first_deployment_for(merge_request.diff_head_sha)
  end

  def deployed_at
    deployment.try(:created_at)
  end
end
