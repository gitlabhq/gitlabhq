# frozen_string_literal: true

module Mutations
  module Metrics
    module Dashboard
      module Annotations
        class Delete < BaseMutation
          graphql_name 'DeleteAnnotation'

          authorize :admin_metrics_dashboard_annotation

          argument :id, GraphQL::Types::String,
            required: true,
            description: 'Global ID of the annotation to delete.'

          # rubocop:disable Lint/UnusedMethodArgument
          def resolve(id:)
            raise_resource_not_available_error!
          end
          # rubocop:enable Lint/UnusedMethodArgument
        end
      end
    end
  end
end
