# frozen_string_literal: true

module QA
  module Resource
    module Errors
      ResourceFabricationFailedError = Class.new(RuntimeError)
      ResourceNotDeletedError = Class.new(RuntimeError)
      ResourceNotFoundError = Class.new(RuntimeError)
      ResourceQueryError = Class.new(RuntimeError)
      ResourceUpdateFailedError = Class.new(RuntimeError)
      ResourceURLMissingError = Class.new(RuntimeError)
      InternalServerError = Class.new(RuntimeError)
    end
  end
end
