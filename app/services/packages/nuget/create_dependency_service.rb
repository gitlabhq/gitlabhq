# frozen_string_literal: true
module Packages
  module Nuget
    class CreateDependencyService < BaseService
      def initialize(package, dependencies = [])
        @package = package
        @dependencies = dependencies
      end

      def execute
        return if @dependencies.empty?

        @package.transaction do
          create_dependency_links
          create_dependency_link_metadata
        end
      end

      private

      def create_dependency_links
        ::Packages::CreateDependencyService
          .new(@package, dependencies_for_create_dependency_service)
          .execute
      end

      def create_dependency_link_metadata
        inserted_links = ::Packages::DependencyLink.preload_dependency
                                                   .for_package(@package)

        return if inserted_links.empty?

        rows = inserted_links.map do |dependency_link|
          raw_dependency = raw_dependency_for(dependency_link.dependency)

          next if raw_dependency[:target_framework].blank?

          {
            dependency_link_id: dependency_link.id,
            target_framework: raw_dependency[:target_framework]
          }
        end

        ::ApplicationRecord.legacy_bulk_insert(::Packages::Nuget::DependencyLinkMetadatum.table_name, rows.compact) # rubocop:disable Gitlab/BulkInsert
      end

      def raw_dependency_for(dependency)
        name = dependency.name
        version = dependency.version_pattern.presence

        @dependencies.find do |raw_dependency|
          raw_dependency[:name] == name && raw_dependency[:version] == version
        end
      end

      def dependencies_for_create_dependency_service
        names_and_versions = @dependencies.to_h do |dependency|
          [dependency[:name], version_or_empty_string(dependency[:version])]
        end

        { 'dependencies' => names_and_versions }
      end

      def version_or_empty_string(version)
        return '' if version.blank?

        version
      end
    end
  end
end
