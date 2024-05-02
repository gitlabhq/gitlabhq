# frozen_string_literal: true

module Mutations
  module Packages
    class BulkDestroy < ::Mutations::BaseMutation
      graphql_name 'DestroyPackages'

      MAX_PACKAGES = 20
      TOO_MANY_IDS_ERROR = "Cannot delete more than #{MAX_PACKAGES} packages"

      argument :ids,
        [::Types::GlobalIDType[::Packages::Package]],
        required: true,
        description: "Global IDs of the Packages. Max #{MAX_PACKAGES}"

      def resolve(ids:)
        raise_resource_not_available_error!(TOO_MANY_IDS_ERROR) if ids.size > MAX_PACKAGES

        model_ids = ids.map(&:model_id)

        service = ::Packages::MarkPackagesForDestructionService.new(
          packages: packages_from(model_ids),
          current_user: current_user
        )
        result = service.execute

        raise_resource_not_available_error! if result.reason == :unauthorized

        errors = result.error? ? Array.wrap(result[:message]) : []

        { errors: errors }
      end

      private

      def packages_from(ids)
        ::Packages::Package.displayable
                           .id_in(ids)
      end
    end
  end
end
