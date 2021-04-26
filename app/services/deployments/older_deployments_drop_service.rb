# frozen_string_literal: true

module Deployments
  class OlderDeploymentsDropService
    attr_reader :deployment

    def initialize(deployment_id)
      @deployment = Deployment.find_by_id(deployment_id)
    end

    def execute
      return unless @deployment&.running?

      older_deployments.find_each do |older_deployment|
        Gitlab::OptimisticLocking.retry_lock(older_deployment.deployable, name: 'older_deployments_drop') do |deployable|
          deployable.drop(:forward_deployment_failure)
        end
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, subject_id: @deployment.id, deployment_id: older_deployment.id)
      end
    end

    private

    def older_deployments
      @deployment
        .environment
        .active_deployments
        .older_than(@deployment)
        .with_deployable
    end
  end
end
