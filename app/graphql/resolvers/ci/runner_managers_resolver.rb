# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerManagersResolver < BaseResolver
      type Types::Ci::RunnerManagerType.connection_type, null: true

      argument :system_id, ::GraphQL::Types::String,
        required: false,
        description: 'Filter runner managers by system ID.'

      argument :status, ::Types::Ci::RunnerStatusEnum,
        required: false,
        description: 'Filter runner managers by status.'

      def resolve(**args)
        BatchLoader::GraphQL.for(object.id).batch(key: args[:system_id]) do |runner_ids, loader|
          runner_managers =
            ::Ci::RunnerManagersFinder
              .new(runner: runner_ids, params: args.slice(:system_id, :status))
              .execute
          ::Preloaders::RunnerManagerPolicyPreloader.new(runner_managers, current_user).execute

          runner_managers_by_runner_id = runner_managers.group_by(&:runner_id)

          runner_ids.each do |runner_id|
            runner_managers = Array.wrap(runner_managers_by_runner_id[runner_id])
            loader.call(runner_id, runner_managers)
          end
        end
      end
    end
  end
end
