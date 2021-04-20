# frozen_string_literal: true

module Types
  module Packages
    module FileMetadataType
      include ::Types::BaseInterface
      graphql_name 'PackageFileMetadata'
      description 'Represents metadata associated with a Package file'

      field :created_at, ::Types::TimeType, null: false, description: 'Date of creation.'
      field :updated_at, ::Types::TimeType, null: false, description: 'Date of most recent update.'

      def self.resolve_type(object, context)
        case object
        when ::Packages::Conan::FileMetadatum
          ::Types::Packages::Conan::FileMetadatumType
        else
          # NOTE: This method must be kept in sync with `PackageFileType#file_metadata`,
          # which must never produce data that this discriminator cannot handle.
          raise 'Unsupported file metadata type'
        end
      end

      orphan_types Types::Packages::Conan::FileMetadatumType
    end
  end
end
