# frozen_string_literal: true

module Ml
  class UpdateModelService
    def initialize(model, description)
      @model = model
      @description = description
    end

    def execute
      @model.update!(description: @description)

      @model
    end
  end
end
