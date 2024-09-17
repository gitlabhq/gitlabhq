# frozen_string_literal: true

module Ml
  class UpdateModelService
    def initialize(model, description)
      @model = model
      @description = description
    end

    def execute
      return error('Model not found') unless @model

      @model.update!(description: @description)
      success(@model)
    end

    def success(model)
      ServiceResponse.success(payload: model)
    end

    def error(reason)
      ServiceResponse.error(message: reason)
    end
  end
end
