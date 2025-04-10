# frozen_string_literal: true

module Mutations
  module Ci
    module Runner
      class BulkPause < BaseMutation
        graphql_name 'RunnerBulkPause'

        RunnerID = ::Types::GlobalIDType[::Ci::Runner]

        argument :ids, [RunnerID],
          required: true,
          description: 'IDs of the runners to pause or unpause.'

        argument :paused, GraphQL::Types::Boolean,
          required: true,
          description: 'Indicates the runner is not allowed to receive jobs.'

        field :updated_count,
          ::GraphQL::Types::Int,
          null: true,
          description: 'Number of records effectively updated. ' \
            'Only present if operation was performed synchronously.'

        field :updated_runners, # rubocop:disable GraphQL/ExtractType -- Same as bulk_delete
          [Types::Ci::RunnerType],
          null: true,
          description: 'Runners after mutation.'

        def resolve(**runner_attrs)
          response = { updated_count: 0, updated_runners: [], errors: [] }
          ids = runner_attrs[:ids]
          runner_ids = model_ids_of(ids)
          runners = find_all_runners_by_ids(runner_ids)
          if runners.any?
            result = ::Ci::Runners::BulkPauseRunnersService
              .new(runners: runners, current_user: current_user, paused: runner_attrs[:paused])
              .execute
            result.payload.slice(:updated_count, :updated_runners, :errors)
          else
            response
          end
        end

        private

        def model_ids_of(global_ids)
          global_ids.filter_map { |gid| gid.model_id.to_i }
        end

        def find_all_runners_by_ids(ids)
          return ::Ci::Runner.none if ids.blank?

          limit = ::Ci::Runners::BulkPauseRunnersService::RUNNER_LIMIT
          ::Ci::Runner.id_in(ids).limit(limit + 1)
        end
      end
    end
  end
end
