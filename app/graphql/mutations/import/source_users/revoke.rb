# frozen_string_literal: true

module Mutations
  module Import
    module SourceUsers
      class Revoke < BaseMutation
        graphql_name 'ImportSourceUserRevoke'

        argument :id, Types::GlobalIDType[::Import::SourceUser],
          required: true,
          description: 'Global ID of the mapping of a user on source instance to a user on destination instance.'

        field :import_source_user,
          Types::Import::SourceUserType,
          null: true,
          description: "Mapping of a user on source instance to a user on destination instance after mutation."

        authorize :revoke_placeholder_reassignment

        authorize_granular_token permissions: :revoke_placeholder_reassignment,
          boundary: :user,
          boundary_type: :user

        def resolve(args)
          if Feature.disabled?(:revoke_import_source_user_reassignment, current_user)
            raise_resource_not_available_error! '`revoke_import_source_user_reassignment` feature flag is disabled.'
          end

          import_source_user = authorized_find!(id: args[:id])
          result = ::Import::SourceUsers::RevokeReassignmentService.new(import_source_user,
            current_user: current_user).execute

          { import_source_user: result.payload, errors: result.errors }
        end
      end
    end
  end
end
