# frozen_string_literal: true

# Deprecated:
#   Remove from MutationType during any major release.
module Mutations
  module Metrics
    module Dashboard
      module Annotations
        class Delete < BaseMutation
          graphql_name 'DeleteAnnotation'

          argument :id, GraphQL::Types::String,
            required: true,
            description: 'Global ID of the annotation to delete.'

          def resolve(_args)
            raise_resource_not_available_error!
          end
        end
      end
    end
  end
end
