# frozen_string_literal: true

module Ml
  class FindModelService
    def initialize(project, name)
      @project = project
      @name = name
    end

    def execute
      Ml::Model.by_project_id_and_name(@project.id, @name)
    end
  end
end
