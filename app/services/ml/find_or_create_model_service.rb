# frozen_string_literal: true

module Ml
  class FindOrCreateModelService
    def initialize(project, name, user = nil, description = nil, metadata = [])
      @project = project
      @name = name
      @description = description
      @metadata = metadata
      @user = user
    end

    def execute
      FindModelService.new(@project, @name).execute ||
        CreateModelService.new(@project, @name, @user, @description, @metadata).execute
    end
  end
end
