# frozen_string_literal: true
module Gitlab
  module Graphql
    module Extensions
      # This extension is meant for resolvers that only support forward looking pagination. So in order to limit
      # confusion for allowed GraphQL pagination arguments on the field, we limit this to just `first` and `after`.
      class ForwardOnlyExternallyPaginatedArrayExtension < ExternallyPaginatedArrayExtension
        def apply
          field.argument :after, GraphQL::Types::String,
            description: "Returns the elements in the list that come after the specified cursor.",
            required: false
          field.argument :first, GraphQL::Types::Int,
            description: "Returns the first _n_ elements from the list.",
            required: false
        end
      end
    end
  end
end
