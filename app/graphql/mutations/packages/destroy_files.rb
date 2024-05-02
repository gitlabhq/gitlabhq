# frozen_string_literal: true

module Mutations
  module Packages
    class DestroyFiles < ::Mutations::BaseMutation
      graphql_name 'DestroyPackageFiles'

      include FindsProject

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

        result = ::Packages::MarkPackageFilesForDestructionService.new(package_files).execute

        errors = result.error? ? Array.wrap(result[:message]) : []

        { errors: errors }
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
    end
  end
end
