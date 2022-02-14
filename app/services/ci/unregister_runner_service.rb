# frozen_string_literal: true

module Ci
  class UnregisterRunnerService
    attr_reader :runner

    # @param [Ci::Runner] runner the runner to unregister/destroy
    def initialize(runner)
      @runner = runner
    end

    def execute
      @runner&.destroy
    end
  end
end
