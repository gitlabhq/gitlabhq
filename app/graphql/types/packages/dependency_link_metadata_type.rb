# frozen_string_literal: true

module Types
  module Packages
    class DependencyLinkMetadataType < BaseUnion
      graphql_name 'DependencyLinkMetadata'
      description 'Represents metadata associated with a dependency link'

      possible_types ::Types::Packages::Nuget::DependencyLinkMetadatumType

      def self.resolve_type(object, context)
        case object
        when ::Packages::Nuget::DependencyLinkMetadatum
          ::Types::Packages::Nuget::DependencyLinkMetadatumType
        else
          # NOTE: This method must be kept in sync with `PackageDependencyLinkType#metadata`,
          # which must never produce data that this discriminator cannot handle.
          raise 'Unsupported metadata type'
        end
      end
    end
  end
end
