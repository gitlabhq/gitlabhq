# frozen_string_literal: true

module Types
  module Packages
    module Helm
      class FileMetadatumType < BaseObject
        graphql_name 'HelmFileMetadata'
        description 'Helm file metadata'

        implements Types::Packages::FileMetadataType

        authorize :read_package

        field :channel, GraphQL::Types::String, null: false, description: 'Channel of the Helm chart.'
        field :metadata, Types::Packages::Helm::MetadataType, null: false, description: 'Metadata of the Helm chart.'
      end
    end
  end
end
