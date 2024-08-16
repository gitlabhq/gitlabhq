# frozen_string_literal: true

# Deprecated:
#   Remove from MutationType during any major release.
module Mutations
  module Metrics
    module Dashboard
      module Annotations
        class Create < BaseMutation
          graphql_name 'CreateAnnotation'

          field :annotation,
            Types::Metrics::Dashboards::AnnotationType,
            null: true,
            description: 'Created annotation.'

          argument :environment_id,
            ::Types::GlobalIDType[::Environment],
            required: false,
            description: 'Global ID of the environment to add an annotation to.'

          argument :cluster_id,
            ::Types::GlobalIDType[::Clusters::Cluster],
            required: false,
            description: 'Global ID of the cluster to add an annotation to.'

          argument :starting_at, Types::TimeType,
            required: true,
            description: 'Timestamp indicating starting moment to which the annotation relates.'

          argument :ending_at, Types::TimeType,
            required: false,
            description: 'Timestamp indicating ending moment to which the annotation relates.'

          argument :dashboard_path,
            GraphQL::Types::String,
            required: true,
            description: 'Path to a file defining the dashboard on which the annotation should be added.'

          argument :description,
            GraphQL::Types::String,
            required: true,
            description: 'Description of the annotation.'

          def resolve(_args)
            raise_resource_not_available_error!
          end
        end
      end
    end
  end
end
