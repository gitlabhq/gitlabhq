# frozen_string_literal: true

module Ml
  class CreateExperimentService
    def initialize(project, experiment_name, user = nil)
      @project = project
      @name = experiment_name
      @user = user
    end

    def execute
      experiment = Ml::Experiment.new(project: project, name: name, user: user)
      experiment.save

      return error(experiment.errors.full_messages) unless experiment.persisted?

      success(experiment)
    end

    private

    def success(model)
      ServiceResponse.success(payload: model)
    end

    def error(reason)
      ServiceResponse.error(message: reason)
    end

    attr_reader :project, :name, :user
  end
end
