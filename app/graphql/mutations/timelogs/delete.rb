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

      # A timelog on a project issuable resolves through `project`; one on a
      # group-level work item has no project and resolves through `namespace`
      # to its group. Both are declared because either can be the real
      # boundary, and BoundaryExtractor discards the directive whose resolved
      # object does not match its declared boundary_type.
      authorize_granular_token permissions: :delete_timelog,
        boundaries: [
          { boundary_argument: :id, boundary: :project, boundary_type: :project },
          { boundary_argument: :id, boundary: :namespace, boundary_type: :group }
        ]

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
