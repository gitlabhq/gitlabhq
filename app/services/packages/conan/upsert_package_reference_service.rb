# frozen_string_literal: true

module Packages
  module Conan
    class UpsertPackageReferenceService
      include Gitlab::Utils::StrongMemoize

      UNIQUENESS_COLUMNS = %i[package_id reference].freeze
      UNIQUENESS_COLUMNS_WITH_REVISION = %i[package_id recipe_revision_id reference].freeze

      def initialize(package, package_reference_value, recipe_revision_id = nil)
        @package = package
        @package_reference_value = package_reference_value
        @recipe_revision_id = recipe_revision_id
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

      attr_reader :package, :package_reference_value, :recipe_revision_id

      def package_reference
        package.conan_package_references.build(
          reference: package_reference_value,
          project_id: package.project_id,
          recipe_revision_id: recipe_revision_id
        )
      end
      strong_memoize_attr :package_reference

      def upsert_package_reference
        ::Packages::Conan::PackageReference
          .upsert(
            package_reference.attributes.slice('package_id', 'project_id', 'reference', 'recipe_revision_id'),
            unique_by: uniqueness_constraint_columns
          )
      end

      # Two uniqueness constraints are used:
      # - (package_id, reference) when recipe_revision_id is NULL
      # - (package_id, recipe_revision_id, reference) when recipe_revision_id is present
      # This allows having the same package_id/reference pair with different recipe_revision_id values
      def uniqueness_constraint_columns
        recipe_revision_id.nil? ? UNIQUENESS_COLUMNS : UNIQUENESS_COLUMNS_WITH_REVISION
      end
    end
  end
end
