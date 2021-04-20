# frozen_string_literal: true

module Packages
  module Rubygems
    class CreateDependenciesService
      include BulkInsertSafe

      def initialize(package, gemspec)
        @package = package
        @gemspec = gemspec
      end

      def execute
        set_dependencies
      end

      private

      attr_reader :package, :gemspec

      def set_dependencies
        Packages::Dependency.transaction do
          dependency_type_rows = gemspec.dependencies.map do |dependency|
            dependency = Packages::Dependency.safe_find_or_create_by!(
              name: dependency.name,
              version_pattern: dependency.requirement.to_s
            )

            {
              dependency_id: dependency.id,
              package_id: package.id,
              dependency_type: :dependencies
            }
          end

          package.dependency_links.upsert_all(
            dependency_type_rows,
            unique_by: %i[package_id dependency_id dependency_type]
          )
        end
      end
    end
  end
end
