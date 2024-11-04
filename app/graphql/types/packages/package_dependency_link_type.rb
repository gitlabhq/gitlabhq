# frozen_string_literal: true

module Types
  module Packages
    class PackageDependencyLinkType < BaseObject
      graphql_name 'PackageDependencyLink'
      description 'Represents a package dependency link'
      authorize :read_package

      field :dependency, Types::Packages::PackageDependencyType, null: true, description: 'Dependency.'
      field :dependency_type, Types::Packages::PackageDependencyTypeEnum, null: false, description: 'Dependency type.'
      field :id, ::Types::GlobalIDType[::Packages::DependencyLink], null: false,
        description: 'ID of the dependency link.'
      field :metadata, Types::Packages::DependencyLinkMetadataType, null: true, description: 'Dependency link metadata.'

      # NOTE: This method must be kept in sync with the union
      # type: `Types::Packages::DependencyLinkMetadata`.
      #
      # `Types::Packages::DependencyLinkMetadata.resolve_type(metadata, ctx)` must never raise.
      def metadata
        model_class = case object.package.package_type
                      when 'nuget'
                        ::Packages::Nuget::DependencyLinkMetadatum
                      end

        return unless model_class

        # rubocop: disable CodeReuse/ActiveRecord
        BatchLoader::GraphQL.for(object.id).batch do |ids, loader|
          results = model_class.where(dependency_link_id: ids)
          results.each { |record| loader.call(record.dependency_link_id, record) }
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end

      def dependency
        ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Packages::Dependency, object.dependency_id).find
      end
    end
  end
end
