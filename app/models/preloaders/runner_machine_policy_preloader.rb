# frozen_string_literal: true

module Preloaders
  class RunnerMachinePolicyPreloader
    def initialize(runner_machines, current_user)
      @runner_machines = runner_machines
      @current_user = current_user
    end

    def execute
      return if runner_machines.is_a?(ActiveRecord::NullRelation)

      ActiveRecord::Associations::Preloader.new(
        records: runner_machines,
        associations: [:runner]
      ).call
    end

    private

    attr_reader :runner_machines, :current_user
  end
end
