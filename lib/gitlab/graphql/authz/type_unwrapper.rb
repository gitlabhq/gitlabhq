# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      # Shared module for unwrapping GraphQL type wrappers
      module TypeUnwrapper
        private

        # Unwraps GraphQL type wrappers to get to the underlying type
        # Handles:
        # - List types: [Type] -> Type
        # - NonNull types: Type! -> Type
        # - Connection types: TypeConnection -> Type
        def unwrap_type(type)
          if type.respond_to?(:of_type) && type.of_type
            unwrap_type(type.of_type)
          elsif type.respond_to?(:node_type) && type.node_type
            type.node_type
          else
            type
          end
        end
      end
    end
  end
end
