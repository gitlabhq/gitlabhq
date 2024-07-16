# frozen_string_literal: true

module Mutations
  module Import
    module SourceUsers
      class CancelReassignment < BaseMutation
        graphql_name 'ImportSourceUserCancelReassignment'

        argument :id, Types::GlobalIDType[::Import::SourceUser],
          required: true,
          description: 'Global ID of the mapping of a user on source instance to a user on destination instance.'

        field :import_source_user,
          Types::Import::SourceUserType,
          null: true,
          description: "Mapping of a user on source instance to a user on destination instance after mutation."

        authorize :admin_import_source_user

        def resolve(args)
          if Feature.disabled?(:importer_user_mapping, current_user)
            raise_resource_not_available_error! '`importer_user_mapping` feature flag is disabled.'
          end

          import_source_user = authorized_find!(id: args[:id])
          result = ::Import::SourceUsers::CancelReassignmentService.new(import_source_user,
            current_user: current_user).execute

          { import_source_user: result.payload, errors: result.errors }
        end
      end
    end
  end
end
