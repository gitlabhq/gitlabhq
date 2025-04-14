# frozen_string_literal: true

module Packages
  module Conan
    class UpsertPackageRevisionService
      include Gitlab::Utils::StrongMemoize

      UNIQUENESS_COLUMNS = %i[package_id package_reference_id revision].freeze

      def initialize(package, package_reference_id, revision)
        @package = package
        @package_reference_id = package_reference_id
        @revision = revision
      end

      def execute!
        # We use a different validation context
        # so that the uniqueness model validation on
        # [package_id, package_reference_id, revision]
        # is skipped.
        package_revision.validate!(:upsert)

        ServiceResponse.success(payload: { package_revision_id: upsert_package_revision[0]['id'] })
      end

      private

      attr_reader :package, :package_reference_id, :revision

      def package_revision
        package.conan_package_revisions.build(
          package_reference_id: package_reference_id,
          revision: revision,
          project_id: package.project_id
        )
      end
      strong_memoize_attr :package_revision

      def upsert_package_revision
        ::Packages::Conan::PackageRevision
          .upsert(
            package_revision.attributes.slice('package_id', 'project_id', 'package_reference_id', 'revision'),
            unique_by: UNIQUENESS_COLUMNS
          )
      end
    end
  end
end
