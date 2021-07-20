# frozen_string_literal: true

module Mutations
  module Packages
    class Destroy < ::Mutations::BaseMutation
      graphql_name 'DestroyPackage'

      authorize :destroy_package

      argument :id,
               ::Types::GlobalIDType[::Packages::Package],
               required: true,
               description: 'ID of the Package.'

      def resolve(id:)
        package = authorized_find!(id: id)

        result = ::Packages::DestroyPackageService.new(container: package, current_user: current_user).execute

        errors = result.error? ? Array.wrap(result[:message]) : []

        {
          errors: errors
        }
      end

      private

      def find_object(id:)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::Packages::Package].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
