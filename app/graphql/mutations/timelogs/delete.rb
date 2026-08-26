# frozen_string_literal: true

module Mutations
  module Timelogs
    class Delete < Base
      graphql_name 'TimelogDelete'

      argument :id,
        ::Types::GlobalIDType[::Timelog],
        required: true,
        description: 'Global ID of the timelog.'

      authorize :delete_timelog

      # Project boundary only: the role definitions grant timelog deletion
      # abilities at project scope only, so deleting a timelog on a
      # group-level work item is denied for every role and a group boundary
      # could never grant access. Group-level timelogs fail closed
      # (unresolvable boundary). Extend when group-scope grants exist.
      authorize_granular_token permissions: :delete_timelog,
        boundary_argument: :id, boundary: :project, boundary_type: :project

      def resolve(id:)
        timelog = authorized_find!(id: id)
        result = ::Timelogs::DeleteService.new(timelog, current_user).execute

        # Return the result payload, not the loaded timelog, so that it returns null in case of unauthorized access
        response(result)
      end

      private

      def find_object(id:)
        GitlabSchema.object_from_id(id, expected_type: ::Timelog).sync
      end
    end
  end
end
