# frozen_string_literal: true

module Preloaders
  class RunnerManagerPolicyPreloader
    def initialize(runner_managers, current_user)
      @runner_managers = runner_managers
      @current_user = current_user
    end

    def execute
      return if runner_managers.is_a?(ActiveRecord::Relation) && runner_managers.null_relation?

      ActiveRecord::Associations::Preloader.new(
        records: runner_managers,
        associations: [:runner]
      ).call
    end

    private

    attr_reader :runner_managers, :current_user
  end
end
