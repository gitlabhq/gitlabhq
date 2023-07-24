# frozen_string_literal: true

module Ml
  class FindOrCreateModelService
    def initialize(project, model_name)
      @project = project
      @name = model_name
    end

    def execute
      Ml::Model.find_or_create(
        project,
        name,
        Ml::FindOrCreateExperimentService.new(project, name).execute
      )
    end

    private

    attr_reader :name, :project
  end
end
