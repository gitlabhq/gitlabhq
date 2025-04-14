# frozen_string_literal: true

# This class represents a CI input value that has been persisted and can be passed to pipelines created in its project.
# For example, users can configure CI input values when creating pipeline schedules.
# Those values are then passed to pipelines created by the schedule.

module Types
  module Ci
    module Inputs
      # rubocop:disable Graphql:AuthorizeTypes -- Authorization will always be handled by the fields that use this type
      class FieldType < BaseObject
        graphql_name 'CiInputsField'
        description 'CI input saved for a pipeline schedule'

        field :name,
          GraphQL::Types::String,
          null: false,
          description: 'Name of the input.'

        field :value,
          Inputs::ValueType,
          null: true,
          description: 'Value of the input.'
      end
      # rubocop:enable Graphql:AuthorizeTypes
    end
  end
end
