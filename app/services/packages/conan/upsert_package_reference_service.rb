# frozen_string_literal: true

module Packages
  module Conan
    class UpsertPackageReferenceService
      include Gitlab::Utils::StrongMemoize

      def initialize(package, package_reference_value)
        @package = package
        @package_reference_value = package_reference_value
      end

      def execute!
        # We use a different validation context
        # so that the uniqueness model validation on
        # [reference, package_id, recipe_revision_id]
        # is skipped.
        package_reference.validate!(:upsert)

        ServiceResponse.success(payload: { package_reference_id: upsert_package_reference[0]['id'] })
      end

      private

      attr_reader :package, :package_reference_value

      def package_reference
        ::Packages::Conan::PackageReference.new(
          package_id: package.id,
          reference: package_reference_value,
          project_id: package.project_id
        )
      end
      strong_memoize_attr :package_reference

      def upsert_package_reference
        ::Packages::Conan::PackageReference
          .upsert(
            package_reference.attributes.slice('package_id', 'project_id', 'reference'),
            unique_by: %i[package_id reference]
          )
      end
    end
  end
end
