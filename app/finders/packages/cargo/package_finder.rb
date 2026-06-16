# frozen_string_literal: true

module Packages
  module Cargo
    class PackageFinder
      def initialize(project, package_name:, package_version:)
        @project = project
        @package_name = package_name
        @package_version = package_version
      end

      def execute
        return ::Packages::Cargo::Package.none if package_name.blank?
        return ::Packages::Cargo::Package.none if package_version.blank?
        return ::Packages::Cargo::Package.none if project.nil?

        ::Packages::Cargo::Package
          .for_projects(project)
          .installable
          .with_normalized_cargo_metadata(project.id, package_name, package_version)
      end

      private

      attr_reader :project, :package_name, :package_version
    end
  end
end
