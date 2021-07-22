# frozen_string_literal: true

module Types
  module Packages
    module Pypi
      class MetadatumType < BaseObject
        graphql_name 'PypiMetadata'
        description 'Pypi metadata'

        authorize :read_package

        field :id, ::Types::GlobalIDType[::Packages::Pypi::Metadatum], null: false, description: 'ID of the metadatum.'
        field :required_python, GraphQL::Types::String, null: true, description: 'Required Python version of the Pypi package.'
      end
    end
  end
end
