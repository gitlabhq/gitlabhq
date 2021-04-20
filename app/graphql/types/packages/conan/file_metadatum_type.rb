# frozen_string_literal: true

module Types
  module Packages
    module Conan
      class FileMetadatumType < BaseObject
        graphql_name 'ConanFileMetadata'
        description 'Conan file metadata'

        implements Types::Packages::FileMetadataType

        authorize :read_package

        field :id, ::Types::GlobalIDType[::Packages::Conan::FileMetadatum], null: false, description: 'ID of the metadatum.'
        field :recipe_revision, GraphQL::STRING_TYPE, null: false, description: 'Revision of the Conan recipe.'
        field :package_revision, GraphQL::STRING_TYPE, null: true, description: 'Revision of the package.'
        field :conan_package_reference, GraphQL::STRING_TYPE, null: true, description: 'Reference of the Conan package.'
        field :conan_file_type, ::Types::Packages::Conan::MetadatumFileTypeEnum, null: false, description: 'Type of the Conan file.'
      end
    end
  end
end
