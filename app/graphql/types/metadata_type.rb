# frozen_string_literal: true

module Types
  class MetadataType < ::Types::BaseObject
    graphql_name 'Metadata'

    authorize :read_instance_metadata

    field :version, GraphQL::Types::String, null: false,
          description: 'Version.'
    field :revision, GraphQL::Types::String, null: false,
          description: 'Revision.'
    field :kas, ::Types::Metadata::KasType, null: false,
          description: 'Metadata about KAS.'
  end
end
