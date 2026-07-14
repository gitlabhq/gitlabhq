# frozen_string_literal: true

module Packages
  module Cargo
    class MetadataFinder
      MAX_VERSIONS = 500

      def initialize(project, package_name:)
        @project = project
        @package_name = package_name
      end

      def execute
        return ::Packages::Cargo::Metadatum.none if project.nil?
        return ::Packages::Cargo::Metadatum.none if package_name.blank?

        ::Packages::Cargo::Metadatum
          .for_project_and_normalized_name(project, ::Packages::Cargo.normalize_name(package_name))
          .with_installable_package
          .order_by_package_id_desc
          .limit(MAX_VERSIONS)
      end

      private

      attr_reader :project, :package_name
    end
  end
end
