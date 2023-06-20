# frozen_string_literal: true

module Packages
  module Composer
    class CreatePackageService < ::Packages::CreatePackageService
      include ::Gitlab::Utils::StrongMemoize

      def execute
        # fetches json outside of transaction
        composer_json

        ::Packages::Package.transaction do
          ::Packages::Composer::Metadatum.upsert({
            package_id: created_package.id,
            target_sha: target,
            composer_json: composer_json
          })
        end

        created_package
      end

      private

      def created_package
        find_or_create_package!(:composer, name: package_name, version: package_version)
      end

      def composer_json
        ::Packages::Composer::ComposerJsonService.new(project, target).execute
      end
      strong_memoize_attr :composer_json

      def package_name
        composer_json['name']
      end

      def target
        (branch || tag).target
      end

      def branch
        params[:branch]
      end

      def tag
        params[:tag]
      end

      def package_version
        ::Packages::Composer::VersionParserService.new(tag_name: tag&.name, branch_name: branch&.name).execute
      end
    end
  end
end
