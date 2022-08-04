# frozen_string_literal: true

module Mutations
  module Ci
    module Runner
      class BulkDelete < BaseMutation
        graphql_name 'BulkRunnerDelete'

        RunnerID = ::Types::GlobalIDType[::Ci::Runner]

        argument :ids, [RunnerID],
                 required: false,
                 description: 'IDs of the runners to delete.'

        field :deleted_count,
              ::GraphQL::Types::Int,
              null: true,
              description: 'Number of records effectively deleted. ' \
                'Only present if operation was performed synchronously.'

        field :deleted_ids,
              [RunnerID],
              null: true,
              description: 'IDs of records effectively deleted. ' \
                'Only present if operation was performed synchronously.'

        def resolve(**runner_attrs)
          raise_resource_not_available_error! unless Ability.allowed?(current_user, :delete_runners)

          if ids = runner_attrs[:ids]
            runners = find_all_runners_by_ids(model_ids_of(ids))

            result = ::Ci::Runners::BulkDeleteRunnersService.new(runners: runners).execute
            result.slice(:deleted_count, :deleted_ids).merge(errors: [])
          else
            { errors: [] }
          end
        end

        private

        def model_ids_of(ids)
          ids.map do |gid|
            gid.model_id.to_i
          end.compact
        end

        def find_all_runners_by_ids(ids)
          return ::Ci::Runner.none if ids.blank?

          ::Ci::Runner.id_in(ids)
        end
      end
    end
  end
end
