module Gitlab
  module Graphql
    module Errors
      BaseError = Class.new(GraphQL::ExecutionError)
      ArgumentError = Class.new(BaseError)
      ResourceNotAvailable = Class.new(BaseError)
    end
  end
end
