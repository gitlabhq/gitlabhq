# frozen_string_literal: true

module Types
  module Ci
    class RunnerType < BaseObject
      graphql_name 'CiRunner'
      authorize :read_runner

      JOB_COUNT_LIMIT = 1000

      alias_method :runner, :object

      field :id, ::Types::GlobalIDType[::Ci::Runner], null: false,
            description: 'ID of the runner.'
      field :description, GraphQL::STRING_TYPE, null: true,
            description: 'Description of the runner.'
      field :contacted_at, Types::TimeType, null: true,
            description: 'Last contact from the runner.',
            method: :contacted_at
      field :maximum_timeout, GraphQL::INT_TYPE, null: true,
            description: 'Maximum timeout (in seconds) for jobs processed by the runner.'
      field :access_level, ::Types::Ci::RunnerAccessLevelEnum, null: false,
            description: 'Access level of the runner.'
      field :active, GraphQL::BOOLEAN_TYPE, null: false,
            description: 'Indicates the runner is allowed to receive jobs.'
      field :status, ::Types::Ci::RunnerStatusEnum, null: false,
            description: 'Status of the runner.'
      field :version, GraphQL::STRING_TYPE, null: false,
            description: 'Version of the runner.'
      field :short_sha, GraphQL::STRING_TYPE, null: true,
            description: %q(First eight characters of the runner's token used to authenticate new job requests. Used as the runner's unique ID.)
      field :revision, GraphQL::STRING_TYPE, null: false,
            description: 'Revision of the runner.'
      field :locked, GraphQL::BOOLEAN_TYPE, null: true,
            description: 'Indicates the runner is locked.'
      field :run_untagged, GraphQL::BOOLEAN_TYPE, null: false,
            description: 'Indicates the runner is able to run untagged jobs.'
      field :ip_address, GraphQL::STRING_TYPE, null: false,
            description: 'IP address of the runner.'
      field :runner_type, ::Types::Ci::RunnerTypeEnum, null: false,
            description: 'Type of the runner.'
      field :tag_list, [GraphQL::STRING_TYPE], null: true,
            description: 'Tags associated with the runner.'
      field :project_count, GraphQL::INT_TYPE, null: true,
            description: 'Number of projects that the runner is associated with.'
      field :job_count, GraphQL::INT_TYPE, null: true,
            description: "Number of jobs processed by the runner (limited to #{JOB_COUNT_LIMIT}, plus one to indicate that more items exist)."

      def job_count
        # We limit to 1 above the JOB_COUNT_LIMIT to indicate that more items exist after JOB_COUNT_LIMIT
        runner.builds.limit(JOB_COUNT_LIMIT + 1).count
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def project_count
        BatchLoader::GraphQL.for(runner.id).batch(key: :runner_project_count) do |ids, loader, args|
          counts = ::Ci::Runner.project_type
            .select(:id, 'COUNT(ci_runner_projects.id) as count')
            .left_outer_joins(:runner_projects)
            .where(id: ids)
            .group(:id)
            .index_by(&:id)

          ids.each do |id|
            loader.call(id, counts[id]&.count)
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end

Types::Ci::RunnerType.prepend_mod_with('Types::Ci::RunnerType')
