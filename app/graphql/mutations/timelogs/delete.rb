# frozen_string_literal: true

module Mutations
  module Timelogs
    class Delete < Mutations::BaseMutation
      graphql_name 'TimelogDelete'

      field :timelog,
            Types::TimelogType,
            null: true,
            description: 'Deleted timelog.'

      argument :id,
               ::Types::GlobalIDType[::Timelog],
               required: true,
               description: 'Global ID of the timelog.'

      authorize :admin_timelog

      def resolve(id:)
        timelog = authorized_find!(id: id)
        result = ::Timelogs::DeleteService.new(timelog, current_user).execute

        # Return the result payload, not the loaded timelog, so that it returns null in case of unauthorized access
        { timelog: result.payload, errors: result.errors }
      end

      def find_object(id:)
        # TODO: Remove coercion when working on https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::Timelog].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
