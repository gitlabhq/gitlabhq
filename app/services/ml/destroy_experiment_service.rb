# frozen_string_literal: true

module Ml
  class DestroyExperimentService
    def initialize(experiment)
      @experiment = experiment
    end

    def execute
      if @experiment.destroy
        ServiceResponse.success(payload: payload)
      else
        ServiceResponse.error(message: @experiment.errors.full_messages, payload: payload)
      end
    end

    private

    def payload
      { experiment: @experiment }
    end
  end
end
