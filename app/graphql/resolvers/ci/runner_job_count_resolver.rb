# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerJobCountResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type GraphQL::Types::Int, null: true

      authorize :read_runner
      authorizes_object!

      argument :statuses, [::Types::Ci::JobStatusEnum],
        required: false,
        description: 'Filter jobs by status.',
        experiment: { milestone: '16.2' }

      alias_method :runner, :object

      def resolve(statuses: nil)
        BatchLoader::GraphQL.for(runner.id).batch(key: [:job_count, statuses]) do |runner_ids, loader, _args|
          counts_by_runner = calculate_job_count_per_runner(runner_ids, statuses)

          runner_ids.each do |runner_id|
            loader.call(runner_id, counts_by_runner[runner_id]&.count || 0)
          end
        end
      end

      private

      def calculate_job_count_per_runner(runner_ids, statuses)
        # rubocop: disable CodeReuse/ActiveRecord
        builds_tbl = ::Ci::Build.arel_table
        runners_tbl = ::Ci::Runner.arel_table
        lateral_query = ::Ci::Build.select(1).where(builds_tbl['runner_id'].eq(runners_tbl['id']))
        lateral_query = lateral_query.where(status: statuses) if statuses
        # We limit to 1 above the JOB_COUNT_LIMIT to indicate that more items exist after JOB_COUNT_LIMIT
        lateral_query = lateral_query.limit(::Types::Ci::RunnerType::JOB_COUNT_LIMIT + 1)
        ::Ci::Runner.joins("JOIN LATERAL (#{lateral_query.to_sql}) builds_with_limit ON true")
          .id_in(runner_ids)
          .select(:id, Arel.star.count.as('count'))
          .group(:id)
          .index_by(&:id)
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
