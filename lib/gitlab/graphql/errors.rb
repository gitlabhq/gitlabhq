# frozen_string_literal: true

module Gitlab
  module Graphql
    module Errors
      BaseError = Class.new(GraphQL::ExecutionError)
      ArgumentError = Class.new(BaseError)
      ResourceNotAvailable = Class.new(BaseError)
      MutationError = Class.new(BaseError)
      LimitError = Class.new(BaseError)
      InvalidMembersError = Class.new(StandardError)
      InvalidMemberCountError = Class.new(StandardError)
    end
  end
end
