# frozen_string_literal: true

module Deployments
  class OlderDeploymentsDropService
    attr_reader :deployment

    def initialize(deployment_id)
      @deployment = Deployment.find_by_id(deployment_id)
    end

    def execute
      return unless @deployment&.running?

      older_deployments_builds.each do |build|
        next if build.manual?

        Gitlab::OptimisticLocking.retry_lock(build, name: 'older_deployments_drop') do |build|
          build.drop(:forward_deployment_failure)
        end
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, subject_id: @deployment.id, build_id: build.id)
      end
    end

    private

    def older_deployments_builds
      @deployment
        .environment
        .active_deployments
        .older_than(@deployment)
        .builds
    end
  end
end
