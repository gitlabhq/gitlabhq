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

        result = ::Packages::MarkPackageForDestructionService.new(
          container: package,
          current_user: current_user
        ).execute

        errors = result.error? ? Array.wrap(result[:message]) : []

        {
          errors: errors
        }
      end
    end
  end
end
