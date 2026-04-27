# frozen_string_literal: true

module Mutations
  module Import
    module SourceUsers
      class RetryFailedReassignment < BaseMutation
        graphql_name 'ImportSourceUserRetryFailedReassignment'

        argument :id, Types::GlobalIDType[::Import::SourceUser],
          required: true,
          description: 'Global ID of the mapping of a user on source instance to a user on destination instance.'

        field :import_source_user,
          Types::Import::SourceUserType,
          null: true,
          description: 'Mapping of a user on source instance to a user on destination instance after mutation.'

        authorize :admin_import_source_user

        def resolve(id:)
          import_source_user = authorized_find!(id: id)

          result = ::Import::SourceUsers::RetryFailedReassignmentService.new(
            import_source_user,
            current_user: current_user
          ).execute

          { import_source_user: result.payload, errors: result.errors }
        end
      end
    end
  end
end
