# frozen_string_literal: true

module Mutations
  module Packages
    class Destroy < ::Mutations::BaseMutation
      graphql_name 'DestroyPackage'

      include Mutations::Packages::DeleteProtection

      authorize :destroy_package

      argument :id,
        ::Types::GlobalIDType[::Packages::Package],
        required: true,
        description: 'ID of the Package.'

      def resolve(id:)
        package = authorized_find!(id: id)

        return { errors: [deletion_protected_error_message] } if protected_for_delete?(package)

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
