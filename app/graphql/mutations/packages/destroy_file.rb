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

        if package_file.update(status: :pending_destruction)
          return { errors: [] }
        end

        { errors: package_file.errors.full_messages }
      end
    end
  end
end
