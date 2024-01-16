# frozen_string_literal: true

module Ci
  class RunnerManagersFinder
    def initialize(runner:, params:)
      @runner = runner
      @params = params
    end

    def execute
      items = runner_managers

      filter_by_status(items)
    end

    private

    attr_reader :runner, :params

    def runner_managers
      ::Ci::RunnerManager.for_runner(runner)
    end

    def filter_by_status(items)
      status = params[:status]
      return items if status.blank?

      items.with_status(status)
    end
  end
end
