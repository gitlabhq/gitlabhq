# frozen_string_literal: true

module Types
  module Packages
    module Conan
      class FileMetadatumType < BaseObject
        graphql_name 'ConanFileMetadata'
        description 'Conan file metadata'

        implements Types::Packages::FileMetadataType

        authorize :read_package

        field :conan_file_type, ::Types::Packages::Conan::MetadatumFileTypeEnum, null: false,
          description: 'Type of the Conan file.'
        field :conan_package_reference, GraphQL::Types::String, null: true,
          description: 'Reference of the Conan package.'
        field :id, ::Types::GlobalIDType[::Packages::Conan::FileMetadatum], null: false,
          description: 'ID of the metadatum.'
        field :package_revision, GraphQL::Types::String, null: true, description: 'Revision of the package.',
          method: :package_revision_value
        field :recipe_revision, GraphQL::Types::String, null: false, description: 'Revision of the Conan recipe.',
          method: :recipe_revision_value
      end
    end
  end
end
