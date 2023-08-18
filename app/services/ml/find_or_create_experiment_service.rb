# frozen_string_literal: true

module Ml
  class FindOrCreateExperimentService
    def initialize(project, experiment_name, user = nil)
      @project = project
      @name = experiment_name
      @user = user
    end

    def execute
      Ml::Experiment.find_or_create(project, name, user)
    end

    private

    attr_reader :project, :name, :user
  end
end
