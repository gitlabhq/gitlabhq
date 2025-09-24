# frozen_string_literal: true

module Mutations
  module Packages
    class DestroyFile < ::Mutations::BaseMutation
      graphql_name 'DestroyPackageFile'

      include Mutations::Packages::DeleteProtection

      authorize :destroy_package

      argument :id,
        ::Types::GlobalIDType[::Packages::PackageFile],
        required: true,
        description: 'ID of the Package file.'

      def resolve(id:)
        package_file = authorized_find!(id: id)

        package = package_file.package
        return { errors: [deletion_protected_error_message] } if protected_for_delete?(package)

        if package_file.pending_destruction!
          sync_helm_metadata_cache(package_file)

          return { errors: [] }
        end

        { errors: package_file.errors.full_messages }
      end

      private

      def sync_helm_metadata_cache(package_file)
        return unless package_file.package.helm? && package_file.helm_channel

        # rubocop:disable CodeReuse/Worker -- This is required because we want to sync metadata cache as soon as package files are deleted
        # Related issue: https://gitlab.com/gitlab-org/gitlab/-/work_items/569680
        ::Packages::Helm::CreateMetadataCacheWorker.perform_async(package_file.project_id, package_file.helm_channel)
        # rubocop:enable CodeReuse/Worker
      end
    end
  end
end
