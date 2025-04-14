# frozen_string_literal: true

module Packages
  module Conan
    class UpsertRecipeRevisionService
      include Gitlab::Utils::StrongMemoize

      UNIQUENESS_COLUMNS = %i[package_id revision].freeze

      def initialize(package, revision)
        @package = package
        @revision = revision
      end

      def execute!
        # We use a different validation context
        # so that the uniqueness model validation on
        # [revision, package_id]
        # is skipped.
        recipe_revision.validate!(:upsert)

        ServiceResponse.success(payload: { recipe_revision_id: upsert_recipe_revision[0]['id'] })
      end

      private

      attr_reader :package, :revision

      def recipe_revision
        package.conan_recipe_revisions.build(
          revision: revision,
          project_id: package.project_id
        )
      end
      strong_memoize_attr :recipe_revision

      def upsert_recipe_revision
        ::Packages::Conan::RecipeRevision
          .upsert(
            recipe_revision.attributes.slice('package_id', 'project_id', 'revision'),
            unique_by: UNIQUENESS_COLUMNS
          )
      end
    end
  end
end
