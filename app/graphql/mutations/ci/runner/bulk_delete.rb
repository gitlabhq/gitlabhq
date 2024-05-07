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
          if ids = runner_attrs[:ids]
            runner_ids = model_ids_of(ids)
            runners = find_all_runners_by_ids(runner_ids)

            result = ::Ci::Runners::BulkDeleteRunnersService.new(runners: runners, current_user: current_user).execute
            result.payload.slice(:deleted_count, :deleted_ids, :errors)
          else
            { errors: [] }
          end
        end

        private

        def model_ids_of(global_ids)
          global_ids.filter_map { |gid| gid.model_id.to_i }
        end

        def find_all_runners_by_ids(ids)
          return ::Ci::Runner.none if ids.blank?

          limit = ::Ci::Runners::BulkDeleteRunnersService::RUNNER_LIMIT
          ::Ci::Runner.id_in(ids).limit(limit + 1)
        end
      end
    end
  end
end
