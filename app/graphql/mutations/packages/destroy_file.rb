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

        ::Packages::Helm::BulkSyncHelmMetadataCacheService.new(
          current_user,
          ::Packages::PackageFile.id_in(package_file.id)
        ).execute
      end
    end
  end
end
