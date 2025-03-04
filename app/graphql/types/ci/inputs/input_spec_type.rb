# frozen_string_literal: true

module Types
  module Ci
    module Inputs
      class InputSpecType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- Authorization checked upstream
        graphql_name 'CiInputSpec'

        description 'Input for pipeline creation'

        field :name, GraphQL::Types::String,
          null: false,
          description: 'Name of the input.'

        field :type, Types::Ci::Inputs::InputTypeEnum,
          null: false,
          description: 'Input data type.'

        field :description, GraphQL::Types::String,
          null: true,
          description: 'Description of the input.'

        field :required, GraphQL::Types::Boolean,
          null: false,
          description: 'Indicates whether the input is required.',
          method: :required?

        field :default, Types::Ci::Inputs::ValueInputType,
          null: true,
          description: 'Default value for the input, if provided.'

        field :options, Types::Ci::Inputs::ValueInputType,
          null: true,
          description: 'Possible values that the input can take, if provided.'

        field :regex, GraphQL::Types::String,
          null: true,
          description: 'Regular expression pattern that the input value must match if provided.'
      end
    end
  end
end
