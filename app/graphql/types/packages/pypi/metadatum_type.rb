# frozen_string_literal: true

module Types
  module Packages
    module Pypi
      class MetadatumType < BaseObject
        graphql_name 'PypiMetadata'
        description 'Pypi metadata'

        authorize :read_package

        field :author_email, GraphQL::Types::String, null: true,
          description: 'Author email address(es) in RFC-822 format.'
        field :description, GraphQL::Types::String, null: true,
          description: 'Longer description that can run to several paragraphs.'
        field :description_content_type, GraphQL::Types::String, null: true,
          description: 'Markup syntax used in the description field.'
        field :id, ::Types::GlobalIDType[::Packages::Pypi::Metadatum], null: false, description: 'ID of the metadatum.'
        field :keywords, GraphQL::Types::String, null: true, description: 'List of keywords, separated by commas.'
        field :metadata_version, GraphQL::Types::String, null: true, description: 'Metadata version.'
        field :required_python, GraphQL::Types::String, null: true,
          description: 'Required Python version of the Pypi package.'
        field :summary, GraphQL::Types::String, null: true, description: 'One-line summary of the description.'
      end
    end
  end
end
