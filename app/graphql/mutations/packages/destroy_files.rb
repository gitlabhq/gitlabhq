# frozen_string_literal: true

module Mutations
  module Packages
    class DestroyFiles < ::Mutations::BaseMutation
      graphql_name 'DestroyPackageFiles'

      include FindsProject
      include Mutations::Packages::DeleteProtection

      MAXIMUM_FILES = 100

      authorize :destroy_package

      argument :project_path,
        GraphQL::Types::ID,
        required: true,
        description: 'Project path where the packages cleanup policy is located.'

      argument :ids,
        [::Types::GlobalIDType[::Packages::PackageFile]],
        required: true,
        description: 'IDs of the Package file.'

      def resolve(project_path:, ids:)
        project = authorized_find!(project_path)
        raise_resource_not_available_error! "Cannot delete more than #{MAXIMUM_FILES} files" if ids.size > MAXIMUM_FILES

        package_files = ::Packages::PackageFile.id_in(parse_gids(ids))

        ensure_file_access!(project, package_files)

        files_to_destroy, protection_errors = filter_protected_files(project, package_files)

        # Create relation from filtered IDs
        files_to_destroy_relation = package_files.id_in(files_to_destroy.map(&:id))

        result = ::Packages::MarkPackageFilesForDestructionService.new(files_to_destroy_relation).execute

        sync_helm_metadata_caches(package_files) unless result.error?

        service_errors = result.error? ? Array.wrap(result[:message]) : []
        all_errors = protection_errors + service_errors

        { errors: all_errors }
      end

      private

      def ensure_file_access!(project, package_files)
        project_ids = package_files.map(&:project_id).uniq

        unless project_ids.size == 1 && project_ids.include?(project.id)
          raise_resource_not_available_error! 'All files must be in the requested project'
        end
      end

      def parse_gids(gids)
        GitlabSchema.parse_gids(gids, expected_type: ::Packages::PackageFile).map(&:model_id)
      end

      def sync_helm_metadata_caches(package_files)
        ::Packages::Helm::BulkSyncHelmMetadataCacheService.new(
          current_user, package_files
        ).execute
      end

      def filter_protected_files(project, package_files)
        files_to_destroy = []
        protection_errors = []
        protected_packages_cache = {}

        # We can leverage the fact that a package file has a one-to-one relationship
        # to package and project, so we can pass the project directly
        package_files.preload_package.find_each do |package_file|
          package = package_file.package

          # Cache protection check results per package to avoid duplicate checks
          protected_packages_cache[package.id] ||= protected_for_delete?(package, in_project: project)

          if protected_packages_cache[package.id]
            protection_errors << deletion_protected_error_message(package.name)
          else
            files_to_destroy << package_file
          end
        end

        # Deduplicate error messages
        [files_to_destroy, protection_errors.uniq]
      end
    end
  end
end
