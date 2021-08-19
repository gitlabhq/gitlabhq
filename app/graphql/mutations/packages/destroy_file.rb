# frozen_string_literal: true

module Mutations
  module Packages
    class DestroyFile < ::Mutations::BaseMutation
      graphql_name 'DestroyPackageFile'

      authorize :destroy_package

      argument :id,
               ::Types::GlobalIDType[::Packages::PackageFile],
               required: true,
               description: 'ID of the Package file.'

      def resolve(id:)
        package_file = authorized_find!(id: id)

        if package_file.destroy
          return { errors: [] }
        end

        { errors: package_file.errors.full_messages }
      end

      private

      def find_object(id:)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::Packages::PackageFile].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
