# frozen_string_literal: true

module Environments
  class RecalculateAutoStopService
    attr_reader :deployable, :environment

    def initialize(deployable)
      @deployable = deployable
      @environment = deployable.persisted_environment
    end

    def execute
      return unless can_set_auto_stop? && environment.present?

      auto_stop_in = deployable.expanded_auto_stop_in
      auto_stop_in ||= last_successful_deployable&.expanded_auto_stop_in if can_reset_timer?

      environment.update!(auto_stop_in: auto_stop_in) if auto_stop_in.present?
    end

    private

    # Jobs that start an environment (using `action: start`) can also
    # specify a stop time, however this is handled by the deployment
    # process. Actions other than `start` do not create deployments,
    # so these must be processed separately.
    def can_set_auto_stop?
      deployable.verifies_environment? || can_reset_timer?
    end

    def can_reset_timer?
      deployable.prepares_environment? || deployable.accesses_environment?
    end

    def last_successful_deployable
      environment.last_deployment&.deployable
    end
  end
end
