# frozen_string_literal: true

module Mutations
  module Packages
    class BulkDestroy < ::Mutations::BaseMutation
      graphql_name 'DestroyPackages'

      include Mutations::Packages::DeleteProtection

      MAX_PACKAGES = 100
      TOO_MANY_IDS_ERROR = "Cannot delete more than #{MAX_PACKAGES} packages"

      argument :ids,
        [::Types::GlobalIDType[::Packages::Package]],
        required: true,
        description: "Global IDs of the Packages. Max #{MAX_PACKAGES}"

      def resolve(ids:)
        raise_resource_not_available_error!(TOO_MANY_IDS_ERROR) if ids.size > MAX_PACKAGES

        model_ids = ids.map(&:model_id)

        packages = packages_from(model_ids)

        packages_to_destroy, protection_errors = filter_protected_packages(packages)

        # Filter the original relation instead of creating a new one
        packages_to_destroy_relation = packages.id_in(packages_to_destroy.map(&:id))

        service = ::Packages::MarkPackagesForDestructionService.new(
          packages: packages_to_destroy_relation,
          current_user: current_user
        )
        result = service.execute

        raise_resource_not_available_error! if result.reason == :unauthorized

        service_errors = result.error? ? Array.wrap(result[:message]) : []
        errors = protection_errors + service_errors

        { errors: errors }
      end

      private

      def packages_from(ids)
        ::Packages::Package.displayable
                           .id_in(ids)
      end

      def filter_protected_packages(packages)
        packages_to_destroy = []
        protection_errors = []

        # Check protection for each package
        packages.preload_project.find_each do |package|
          if protected_for_delete?(package)
            protection_errors << deletion_protected_error_message(package.name)
          else
            packages_to_destroy << package
          end
        end

        [packages_to_destroy, protection_errors]
      end
    end
  end
end
