# frozen_string_literal: true

module Ml
  class FindModelService
    def initialize(project, name = nil, model_id = nil)
      @project = project
      @name = name
      @model_id = model_id
    end

    def execute
      return find_by_model_id if @model_id
      return find_by_project_and_name if @name

      nil
    end

    def find_by_model_id
      Ml::Model.by_project_id_and_id(@project.id, @model_id)
    end

    def find_by_project_and_name
      Ml::Model.by_project_id_and_name(@project.id, @name)
    end
  end
end
