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

        return { errors: [] } if package_file.update(status: :pending_destruction)

        { errors: package_file.errors.full_messages }
      end
    end
  end
end
