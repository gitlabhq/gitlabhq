# frozen_string_literal: true

module Types
  module Packages
    class MetadataType < BaseUnion
      graphql_name 'PackageMetadata'
      description 'Represents metadata associated with a Package'

      possible_types ::Types::Packages::Composer::MetadatumType, ::Types::Packages::Conan::MetadatumType, ::Types::Packages::Maven::MetadatumType, ::Types::Packages::Nuget::MetadatumType, ::Types::Packages::Pypi::MetadatumType

      def self.resolve_type(object, context)
        case object
        when ::Packages::Composer::Metadatum
          ::Types::Packages::Composer::MetadatumType
        when ::Packages::Conan::Metadatum
          ::Types::Packages::Conan::MetadatumType
        when ::Packages::Maven::Metadatum
          ::Types::Packages::Maven::MetadatumType
        when ::Packages::Nuget::Metadatum
          ::Types::Packages::Nuget::MetadatumType
        when ::Packages::Pypi::Metadatum
          ::Types::Packages::Pypi::MetadatumType
        else
          # NOTE: This method must be kept in sync with `PackageWithoutVersionsType#metadata`,
          # which must never produce data that this discriminator cannot handle.
          raise 'Unsupported metadata type'
        end
      end
    end
  end
end
